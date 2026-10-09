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
Grito de monstro gigante, com subida rápida, sustentação rasgada e metálica,
ressonâncias móveis, vozes desafinadas e queda para um rosnado no final.
A referência de timbre indicada pelo usuário foi o rugido de Godzilla;
o efeito é original, sem utilizar gravações dos filmes.
Referência fornecida: https://youtu.be/3T8kYlW2XjQ . Ajuste atual: tom cerca de
quatro semitons abaixo da versão aguda, ressonâncias mais encorpadas e redução
gradual das frequências acima de 3.800 Hz para suavizar o brilho cortante.
Sem gravações, samples ou soundfonts externos. Mono PCM16/44.100 Hz,
com fades nas bordas para evitar estalos.
Para regenerar: `python assets/audio/compose_boss_sounds.py` (requer NumPy).

## minhocao_emerge.wav e minhocao_dash.wav

Efeitos originais sintetizados: emergência de 0,7 segundo com impacto grave,
terra rompendo e água deslocada; investida de 0,5 segundo com deslocamento de
ar e massa grave. Mono PCM16/44.100 Hz, sem samples externos, com fades nas
bordas. O mesmo `compose_boss_sounds.py` regenera os dois arquivos.

## Comparação do rugido: V0, V1 e V2

- `minhocao_roar_v0.wav`: reconstrução determinística da versão aguda anterior
  à redução de cerca de quatro semitons e à suavização dos agudos.
- `minhocao_roar_v1.wav`: cópia exata do arquivo atual `minhocao_roar.wav`.
- `minhocao_roar_v2.wav`: mesmo tom e textura da V1, com ataque de 150 ms,
  sustentação no pico por um segundo e queda até completar dois segundos.

Geradas com `python assets/audio/compare_boss_roars.py` (NumPy).
O arquivo original e a seleção de som do jogo são preservados. A V0 foi
reconstruída a partir do código da versão anterior, sem gravação dos filmes.

## minhocao_roar_v3.wav

Variação da V0, preservando seu tom mais agudo e sua textura original.
Ataque de 40 ms, intensidade sustentada até 1,5 segundo e queda somente
no meio segundo final. Duração total de dois segundos. A intensidade do corpo
é equilibrada suavemente para manter a sustentação sem eliminar a aspereza.
Gerada com `python assets/audio/compare_boss_roars.py --v3`.
O original e as três versões anteriores são preservados.

## minhocao_roar_v4.wav

Variação da V3, com ataque de 200 ms: começa no silêncio e sobe rapidamente
até a intensidade máxima. Mantém a sustentação até 1,5 segundo e a queda no
último meio segundo, com duração total de dois segundos.
Gerada com `python assets/audio/compare_boss_roars.py --v4`, preservando os
arquivos anteriores e a seleção de som atual do jogo.

## minhocao_roar_v5.wav

Variação da V4: subida do silêncio ao máximo em 400 ms e amplitude geral
reduzida em 30% (ganho de 0,70, aproximadamente −3,10 dB), aplicada após a
normalização do arquivo. Mantém sustentação até 1,5 segundo, queda no último
meio segundo e duração total de dois segundos.
Gerada com `python assets/audio/compare_boss_roars.py --v5`.
O arquivo original e todas as versões anteriores são preservados.
