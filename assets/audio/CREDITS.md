# Áudio

## spear_swish.wav

- Autor: qubodup / Iwan Gabovitch.
- Fonte: https://opengameart.org/content/swish-bamboo-stick-weapon-swhoshes
- Pacote original: https://opengameart.org/sites/default/files/swoshes.7z
- Arquivo original: swosh-01.flac.
- Licença declarada na página: CC0, https://creativecommons.org/publicdomain/zero/1.0/
- Alterações: conversão para mono PCM16, remoção de silêncio, normalização e fades de 8 ms.
- Script de preparação: prepare_spear.py.

Demais efeitos: impactos sintetizados pelo projeto, em scripts/sound_effects.gd.

## correnteza_sombria.wav — Correnteza sombria

Trilha original composta para Pesca Mortal nesta sessão com Codex.
Instrumental de 30 segundos, 128 BPM, 16 compassos em 4/4, centro tonal em
ré menor com cor dórica. Cordas dedilhadas de cursos duplos, flauta suave,
baixo, tambor grave, madeira e chocalho, todos sintetizados pelo script
`compose_theme.py`, sem samples, gravações, soundfonts ou melodias de terceiros.

O WAV estéreo PCM16/44.100 Hz contém exatamente 1.323.000 amostras por canal.
Caudas de notas e ecos são somados circularmente para a emenda contínua;
o jogo repete o arquivo inteiro sem silêncio entre as voltas.
Para regenerar: `python assets/audio/compose_theme.py` (requer NumPy).

## correnteza_em_furia.wav — Correnteza em fúria

Trilha de batalha original composta para Pesca Mortal, substituindo a versão
calma na reprodução do jogo. A referência de energia eletrônica foi indicada
pelo usuário: a trilha de Megabonk. Nenhuma melodia ou gravação dessa trilha
foi utilizada. Referência: https://store.steampowered.com/app/4046730/Megabonk_Soundtrack/

30 segundos, 160 BPM, 20 compassos em 4/4. Centro tonal em mi menor, com
dominante maior para tensão na volta ao início. Bumbo em semínimas, caixa e
clap, pratos em semicolcheias, baixo distorcido com saltos de oitava, acordes
sincopados, arpejos FM e melodia de sintetizadores detunados. A segunda frase
ganha reforços de oitava; os últimos quatro compassos intensificam os arpejos.
O volume dos sintetizadores recua brevemente a cada bumbo para abrir espaço.

Todos os instrumentos são sintetizados, sem samples ou soundfonts externos.
WAV estéreo PCM16/44.100 Hz com exatamente 1.323.000 amostras por canal.
Caudas e ecos circulares preservam a continuidade da repetição.
Para regenerar: `python assets/audio/compose_battle_theme.py` (requer NumPy).
A primeira versão foi preservada em `correnteza_sombria.wav`.

## minhocao_roar.wav — Rugido do Minhocão

Efeito original de dois segundos, sintetizado para o surgimento da serpente gigante.
Rugido de garganta aberta, com ataque forte, sustentação, ressonâncias vocais
móveis, sub-harmônicos, aspereza e uma segunda pressão gutural antes de terminar.
Sem gravações, samples ou soundfonts externos. Mono PCM16/44.100 Hz,
com fades nas bordas para evitar estalos.
Para regenerar: `python assets/audio/compose_boss_sounds.py` (requer NumPy).

## minhocao_emerge.wav e minhocao_dash.wav

Efeitos originais sintetizados: emergência de 0,7 segundo com impacto grave,
terra rompendo e água deslocada; investida de 0,5 segundo com deslocamento de
ar e massa grave. Mono PCM16/44.100 Hz, sem samples externos, com fades nas
bordas. O mesmo `compose_boss_sounds.py` regenera os dois arquivos.
