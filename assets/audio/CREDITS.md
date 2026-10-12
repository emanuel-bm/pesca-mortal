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

## minhocao_roar.wav — Rugido oficial do Minhocão (V5)

Efeito original sintetizado, de dois segundos. A versão aprovada usa o timbre
rasgado e metálico da V0: começa no silêncio, sobe ao máximo em 400 ms,
sustenta a intensidade até 1,5 segundo e diminui no último meio segundo.
Amplitude geral reduzida em 30% (ganho de 0,70 aplicado após normalização).
A referência indicada pelo usuário foi o rugido de Godzilla:
https://youtu.be/3T8kYlW2XjQ . Nenhuma gravação dos filmes foi utilizada.
Mono PCM16/44.100 Hz, com fades nas bordas para evitar estalos.
Para regenerar: `python assets/audio/compose_boss_roar.py` (requer NumPy).

## minhocao_emerge.wav e minhocao_dash.wav

Efeitos originais sintetizados: emergência de 0,7 segundo com impacto grave,
terra rompendo e água deslocada; investida de 0,5 segundo com deslocamento de
ar e massa grave. Mono PCM16/44.100 Hz, sem samples externos, com fades nas
bordas. `python assets/audio/compose_boss_sounds.py` regenera os três efeitos.

## Pai do Mato — efeitos originais

Efeitos sintetizados para o jogo, sem gravações, samples ou vozes de terceiros.
Mono PCM16/44.100 Hz, com fades nas bordas e amplitude limitada.

- `pai_log_throw_v1.wav`: 0,325 segundo de deslocamento de ar com peso grave,
  usado no gesto inicial do arremesso; o tempo de voo depende da distância.
- `pai_log_splash_v1.wav`: 1,05 segundo de impacto na água, spray e gotas.
- `pai_hand_slap_v2.wav`: 0,58 segundo de palma mais estridente, com impacto grave de 68 Hz e transientes
  próximos e uma cauda úmida mais curta que a do tronco.
- `pai_roar_v1.wav`: 2,4 segundos de vocalização sintetizada “OOOOOOHHH”,
  com fundamental grave, subida de tom, formantes de vogal O, aspereza e sopro.
  É uma aproximação estilizada de voz envelhecida, não uma gravação humana.

Para regenerar: `python assets/audio/compose_pai_do_mato.py` (requer NumPy). O gerador reutiliza RATE, noise e save de compose_boss_sounds.py, seguindo o processo dos efeitos atuais do Minhocão.
Os quatro efeitos usam o controle independente “Sons do Pai do Mato”.

## Versões arquivadas

V0 a V4 e o arquivo anterior estão preservados em `unused versions/`, junto
com os scripts e os créditos históricos. A pasta pode ser versionada no Git,
mas contém `.gdignore` e é excluída nos presets Windows, macOS e Linux para
não entrar na exportação oficial. Consulte `unused versions/README.md`.

A versão anterior da palma foi preservada em pai_hand_slap_v1.wav. A V2 usa estalo mais brilhante, reforço de grave e volume máximo de 0,65 no jogo.
