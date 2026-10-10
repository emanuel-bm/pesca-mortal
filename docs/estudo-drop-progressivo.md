# Estudo: drop progressivo de cartas

Pesquisa em 09/10/2026. Proposta de design; nenhum código do jogo foi alterado.
O usuário confirmou as bases de **0,25% para piranhas e 1% para pintados**, com
aumento após abates sem carta e reset após um drop.

## Conclusão

É viável: o sorteio já acontece por abate em `scripts/cards.gd`. Bastaria manter
um pequeno estado por partida, calcular a chance antes do sorteio e atualizar
esse estado depois. O ganho desejado é reduzir períodos muito longos sem cartas.
Recomendo um acumulador compartilhado, ponderado pela chance base da espécie,
com crescimento suave e limite de quatro vezes a base. É um modelo próprio,
inspirado na suavização de resultados aleatórios; não é uma reprodução do código
do LoL.

## O que o crítico do LoL ensina

Há duas partes diferentes: chance de um ataque ser crítico e dano causado
quando isso acontece. A Riot voltou o dano crítico base para 200% no patch 26.1,
com exceções e ajustes específicos para campeões e habilidades. Isso significa
dobrar o dano em um caso básico, e não ter 200% de chance. Essa multiplicação
não precisa entrar no sistema de cartas. Fonte: [notas oficiais do patch 26.1](https://www.leagueoflegends.com/en-us/news/game-updates/patch-26-1-notes/).

A parte relevante é usar o histórico dos sorteios. O Doran's Lab coletou ataques
no modo de treino e publicou dados originais em 2018. Encontrou dependência
entre resultados consecutivos e diferenças entre chance exibida e chance
condicional do próximo ataque. A análise de 2020 reutilizou esses dados para
examinar sequências de três ataques; encontrou comportamentos mais complexos
do que simplesmente aumentar a chance a cada falha.
Fontes primárias experimentais: [estudo original de 2018](https://www.doranslab.gg/articles/crit-strike-algorithm.html)
e [reanálise de 2020](https://www.doranslab.gg/articles/crit-strike-revisited.html).

Esses estudos são históricos, não oficiais, e não confirmam o algoritmo vigente
em 2026. Usam o modo de treino e não cobrem todas as chances, mudanças de alvo
ou variações de chance durante a sequência. Não localizei publicação oficial
acessível com a fórmula atual. O link para as notas antigas da Riot, citado
pelos pesquisadores, não abriu. Assim, a evidência permite adotar o princípio
de suavização, mas não atribuir nossa fórmula à Riot.

Existe um exemplo oficial de proteção contra azar no loot do próprio LoL:
os baús Hextech impedem três aberturas seguidas sem fragmento de skin. A Riot
informa que isso eleva a frequência efetiva de aproximadamente 50% para 57%.
É outro sistema, mas ilustra que proteger contra falhas sem compensar a chance
inicial pode aumentar o volume de recompensas.
Fonte: [FAQ oficial de Hextech Crafting](https://support.riotgames.com/en-us/league-of-legends/rewards/hextech-crafting-faq).

## Modelo sugerido para avaliação

Definir `A = 0` ao começar a partida. Para cada abate elegível:

1. Obter `b`: 0,0025 para piranha ou 0,01 para pintado.
2. Sortear com `p = b × min(4, 1 + A)`.
3. Se cair carta, zerar `A` imediatamente; caso contrário, somar `b` a `A`.

O acumulador não é uma probabilidade acumulada de drop: é um peso de proteção.
Uma falha de pintado acrescenta quatro vezes o peso de uma falha de piranha.
Como o mesmo multiplicador vale para as duas espécies, o pintado mantém quatro
vezes a chance da piranha quando comparados no mesmo estado. Isso evita que
um simples contador igual para ambas faça abates de peixes comuns carregar
a chance dos pintados rápido demais.

| Estado sem drop | Chance piranha | Chance pintado |
| --- | ---: | ---: |
| Início, A = 0 | 0,25% | 1% |
| Após 100 piranhas sem carta, A = 0,25 | 0,3125% | 1,25% |
| Após 400 piranhas sem carta, A = 1 | 0,5% | 2% |
| Após 1.200 piranhas sem carta, A = 3 | 1% | 4% |

O teto limita a generosidade, mas **não garante** carta até determinado abate.
Se a intenção futura for eliminar completamente uma seca máxima, será preciso
uma regra de garantia separada. Não recomendo acrescentá-la nesta primeira
proposta sem observar o ritmo real das partidas.

Manter 0,25% e 1% como pisos e só aumentar após falhas necessariamente aumenta
a frequência média em relação ao sorteio independente nessas mesmas bases.
Para preservar exatamente a média seria necessário começar abaixo dela ou
compensar após sucessos; isso diverge da interpretação confirmada pelo usuário.

## Estudo de caso quantitativo

Simulação de 2 milhões de abates por cenário/modelo, sem chefes, com sorteio
de espécie e drop a cada abate. Gerador LCG de 32 bits, seed 417, parâmetros
1664525/1013904223. Intervalos completos entre drops; o intervalo final sem
drop foi descartado das estatísticas de espera. Valores arredondados, sujeitos
à variação amostral. O percentil 95 indica a espera que 95% dos intervalos
completos não ultrapassam; não é uma garantia individual.

| Composição | Modelo | Abates médios entre cartas | Percentil 95 | Cartas por abate |
| --- | --- | ---: | ---: | ---: |
| Só piranhas | Independente, 0,25% | 402,38 | 1.214 | 0,2485% |
| Só piranhas | Progressivo ponderado | 263,24 | 664 | 0,3799% |
| Só pintados | Independente, 1% | 99,92 | 302 | 1,0008% |
| Só pintados | Progressivo ponderado | 65,78 | 163 | 1,5202% |
| 75% piranhas / 25% pintados | Independente | 228,50 | 673 | 0,4376% |
| 75% piranhas / 25% pintados | Progressivo ponderado | 149,73 | 372 | 0,6678% |

Na mistura ilustrativa, intervalos acima de 300 abates caem de 26,95% para
11,39%; acima de 600, de 6,97% para 0,24%. O progressivo gera aproximadamente
53% mais cartas que o retorno simples às bases, mas reduz a espera extrema.

O código atual usa 0,5% e 2%. Com a mesma mistura hipotética, sua taxa teórica
é 0,875%, ou uma carta a cada 114,29 abates em média. Portanto, a proposta
progressiva ainda entrega menos cartas que o estado atual, embora entregue
mais que 0,25% e 1% sem proteção. A composição 75/25 é um cenário de análise,
não uma medição da distribuição de abates do jogo.

## Regras propostas para uma implementação futura

- Usar um acumulador global por partida, não permanente entre partidas.
- Contar apenas abates sujeitos ao sorteio normal de cartas.
- Resetar quando a carta nasce no chão, mesmo que o jogador não a recolha.
- Manter chefes nas regras especiais atuais, sem chance progressiva nem
  incremento por falha; um drop natural garantido também zera o acumulador,
  respeitando o reset após drop confirmado pelo usuário.
- Treino com cartas desabilitadas não acumula proteção.
- Cartas geradas manualmente no treino não alteram o acumulador.
- Inicialização/reinício da partida zera o estado junto do reset de cartas.
- Manter a escolha do tipo de carta separada do sorteio de ocorrência.

As regras de chefes e treino acima são recomendações de design, não decisões
já implementadas. Atualmente o chefe tem chance 100% em infinito/treino e
0% nos demais modos, com a opção de desativar cartas no treino prevalecendo.
O sorteio usa `game.rng.randf()` e a escolha da carta ocorre depois do sucesso.
Fonte local: `scripts/cards.gd`, funções `reset`, `drop_chance`, `drop` e `spawn`.

## Validação antes de aprovar implementação

Medir abates por minuto, proporção real das espécies e cartas coletadas versus
geradas em partidas iniciais e avançadas. Converter as esperas em minutos
usando essas medições: `minutos = abates / abates_por_minuto`. A simulação
não prevê tempo de jogo nem a dificuldade de alcançar os drops.

Se implementado depois, verificar reset, incremento após falha, teto, chefes,
treino e geração manual com sorteios controlados. Comparar a distribuição
de intervalos em um simulador com as bases independentes e com o modelo
aprovado. Evitar testes probabilísticos frágeis no ciclo normal do jogo.

Recomendação: aprovar primeiro a curva ponderada com teto 4× para um teste
de balanceamento posterior. A análise sustenta sua viabilidade técnica e a
redução de secas; o valor final do teto depende do ritmo observado no jogo.

## Apêndice: reprodução dos cenários

Código de análise autocontido em JavaScript; não integra o jogo. `tankRate`
é a proporção de pintados. Cada cenário reinicia a mesma seed. O simulador
considera uma sequência contínua e não inclui resets de partidas ou chefes.

```javascript
for (const tankRate of [0, 0.25, 1]) {
  for (const progressive of [false, true]) {
    let seed = 417;
    const random = () => {
      seed = (Math.imul(seed, 1664525) + 1013904223) >>> 0;
      return seed / 4294967296;
    };
    const total = 2000000;
    const intervals = [];
    let accumulated = 0;
    let waiting = 0;
    for (let kill = 0; kill < total; kill++) {
      const base = random() < tankRate ? 0.01 : 0.0025;
      const chance = progressive
        ? base * Math.min(4, 1 + accumulated)
        : base;
      waiting++;
      if (random() < chance) {
        intervals.push(waiting);
        waiting = 0;
        accumulated = 0;
      } else {
        accumulated += base;
      }
    }
    intervals.sort((a, b) => a - b);
    console.log({
      tankRate,
      progressive,
      mean: intervals.reduce((a, b) => a + b, 0) / intervals.length,
      p95: intervals[Math.floor(intervals.length * 0.95)],
      dropPercent: 100 * intervals.length / total,
      over300Percent: 100 * intervals.filter(n => n > 300).length / intervals.length,
      over600Percent: 100 * intervals.filter(n => n > 600).length / intervals.length,
    });
  }
}
```
