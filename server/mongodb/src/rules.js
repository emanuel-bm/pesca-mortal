// Protocol rules ported from server/apps-script/Code.gs (0.5.0).
export const RULESET = 'pesca-2';
export const LEGACY_VERSION = '0.3';
export const FESTIVAL_ID = 'festival-high-tech-mt';
export function fail_(error, message = '') { return {ok: false, error, message}; }
function better_(next, previous) {
  if (next.seconds !== previous.seconds) return next.mode === 'bosses' ? next.seconds < previous.seconds : next.seconds > previous.seconds;
  return next.kills > previous.kills;
}

function maximumKills_(seconds, mode, ruleset = 'pesca-1') {
  if (ruleset === RULESET) {
    // Current rate: floor(max(2, elapsed / 60) * 1.5), one batch per second.
    const n = Math.floor(seconds + 0.051);
    const blocks = Math.floor(n / 40);
    const fish = blocks < 4 ? 3 * (n + 1)
      : 480 + 40 * ((blocks - 1) * blocks / 2 - 6) + blocks * (n % 40 + 1);
    const waves = Math.max(0, Math.floor((seconds + 0.001 - 180) / 120) + 1);
    const early = Math.min(waves, 5), late = Math.max(0, waves - 5);
    const bosses = mode === 'endless' ? early * (early + 1) / 2 + late * (late + 1) / 2
      : ((seconds + 0.001 >= 120 ? 1 : 0) + (seconds + 0.001 >= 150 ? 1 : 0));
    return fish + bosses + 2;
  }
  // Game ticks clamp dt to 0.05s; spawn batches occur at 0,1,2,... seconds.
  // Sum increasing rates at tick+0.051s, conservatively allowing rounding drift.
  const t = seconds + 0.001;
  const n = Math.floor(t);
  const early = Math.min(n + 1, 300);
  const late = Math.max(0, n - 299);
  const fish = Math.floor(2 * early + (8 / 300) * (early * (early - 1) / 2 + 0.051 * early)
    + 10 * late + (late * (late - 1) / 2 + 0.051 * late) / 30) + 2;
  const waves = Math.floor(t / 90);
  const bosses = mode === 'endless' ? waves * (waves + 1) / 2 : ((t >= 120 ? 1 : 0) + (t >= 150 ? 1 : 0));
  // Simultaneous population cap only reduces possible spawns.
  return fish + bosses;
}

function validateRecord_(r) {
  if (!r || typeof r !== 'object' || Array.isArray(r)) return fail_('invalid_record', 'Resultado inválido.');
  if (r.competitive_version !== undefined && !validVersion_(r.competitive_version)) return fail_('invalid_record', 'Versão competitiva inválida.');
  if (![RULESET, 'pesca-1'].includes(r.ruleset)) return fail_('unsupported_ruleset', 'Versão das regras não suportada.');
  if (compareVersions_(r.competitive_version || LEGACY_VERSION, '0.5') >= 0 && r.ruleset !== RULESET) return fail_('unsupported_ruleset', 'Versão das regras não suportada.');
  if (!['endless', 'bosses'].includes(r.mode) || r.character !== 'Pescador') return fail_('invalid_record', 'Modo ou personagem inválido.');
  if (typeof r.seconds !== 'number' || !Number.isFinite(r.seconds) || r.seconds <= 0 || r.seconds > Number.MAX_SAFE_INTEGER / 1000) return fail_('invalid_record', 'Tempo inválido.');
  if (!Number.isSafeInteger(r.kills) || r.kills < 0 || !Number.isSafeInteger(r.level) || r.level < 1) return fail_('invalid_record', 'Eliminações ou nível inválidos.');
  if (typeof r.run_id !== 'string' || !/^[a-f0-9]{32}$/.test(r.run_id)) return fail_('invalid_record', 'Identificador de partida inválido.');
  if (r.mode === 'bosses' && (r.reason !== 'won' || r.seconds + 0.001 < 150)) return fail_('invalid_record', 'Vitória antes do surgimento do chefão.');
  if (r.mode === 'endless' && !['death', 'menu', 'restart', 'quit'].includes(r.reason)) return fail_('invalid_record', 'Encerramento inválido.');
  if (r.kills > maximumKills_(r.seconds, r.mode, r.ruleset)) return fail_('invalid_record', 'Eliminações acima do máximo possível nesse tempo.');
  // Preserve the 9-XP allowance for ordinary kills; endless bosses yield 100.
  // Allow +20 percentage points per level-up, with no XP bonus cap.
  const waves = r.mode === 'endless' ? Math.max(0, Math.floor((r.seconds + 0.001 - 180) / 120) + 1) : 0;
  const bossKills = Math.min(r.kills, waves * (waves + 1) / 2);
  const xpMultiplier = Math.max(2, 1 + 0.2 * Math.max(0, r.level - 2));
  const current = r.ruleset === RULESET;
  const bossAllowance = r.mode === 'bosses' && current ? Math.min(r.kills, 2) : bossKills;
  const budget = ((r.kills - bossAllowance) * (current ? 20 : 9) + bossAllowance * (current ? 5000 : 100)) * xpMultiplier;
  let required = 0;
  for (let level = 1; level < r.level; level++) {
    required += Math.ceil((5 + (level - 1) * 3) * (current ? 1 : 1.4) * Math.pow(current ? 1.06 : 1.05, level - 1));
    if (required > budget) return fail_('invalid_record', 'Nível incompatível com as eliminações.');
  }
  return null;
}

function validVersion_(value) { return typeof value === 'string' && /^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$/.test(value); }
function compareVersions_(a, b) {
  const left = a.split('.').map(Number), right = b.split('.').map(Number);
  return left[0] - right[0] || left[1] - right[1];
}

export {better_, maximumKills_, validateRecord_, validVersion_, compareVersions_};
