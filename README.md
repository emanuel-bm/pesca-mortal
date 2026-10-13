# Pesca Mortal — protótipo

Beta atual: **0.4.4**. Código, arte, áudio, scripts de servidor e testes estão
incluídos no projeto. Ferramentas locais, caches e builds exportadas ficam
fora do Git; pacotes para jogar são distribuídos pelas Releases.

O menu oferece **Modo infinito** e **Modo por chefões**. O modo por chefões
traz um Minhocão aos três minutos e um Pai do Mato aos seis minutos.
A partida termina em vitória ao derrotar o Pai do Mato.
No infinito, as cinco primeiras ondas trazem apenas Minhocões, em quantidades
de um a cinco. A sexta reinicia a contagem com um Pai do Mato; a sétima tem dois,
a oitava três, e assim por diante. Minhocões de ondas anteriores continuam vivos
até serem derrotados; novas ondas não geram Minhocões depois da quinta.
No infinito, o primeiro chefão aparece aos três minutos. Depois, novas ondas
aparecem a cada dois minutos, com dois chefões na segunda, três na terceira
e assim por diante, sem remover chefões ainda vivos. Cada chefão abatido
multiplica HP, dano e velocidade dos inimigos por 1,05, de forma acumulativa,
atingindo os atuais e os próximos. Tamanho e XP dos peixes não mudam com o buff.
O contador de eliminações inclui chefões no modo infinito.
Cada chefão deixa uma ventrecha gigante de 112 pixels (8 vezes a comum),
com 100 XP base, sujeitos ao bônus de experiência. No modo por chefões,
a partida continua após derrotar o Minhocão e permite coletar seu drop.
As ventrechas usam contorno marrom com espessura de 1,5 pixel.

O histórico do infinito é local, em `user://endless_runs.json`. O ranking ordena
por tempo ativo de sobrevivência, depois por eliminações. Pausas, configurações
e escolhas de melhorias não contam como sobrevivência. Morte, volta ao menu,
reinício e fechamento encerram a run e a registram uma única vez; partidas do
modo por chefões e testes de nível 30 não entram no ranking. O recorde aparece
no menu e o botão Histórico abre a lista completa.

A [pesquisa sobre habilidades e cartas](docs/pesquisa-habilidades.md) descreve
as referências. As [regras das cartas](docs/cartas-em-discussao.md) estão implementadas:
piranhas começam com 1% de chance de drop e pintados com 5%. As chances diminuem
linearmente pelo tempo ativo da partida até 0,25% e 1%, respectivamente, aos
quatro minutos, e permanecem nesses valores depois. Chefões do infinito têm 100%.
O primeiro drop sorteia igualmente Ímã, Fúria, Intangível ou Perfurante. Cada
repetição consecutiva reduz pela metade o peso da última carta, sem impedir
novas repetições. Outra carta encerra a sequência; uma nova partida zera o
histórico. As duas cartas de cada Pai do Mato são sempre diferentes entre si.
Cartas manuais do treino não contam. Coletar ativa
a carta: Ímã atrai todos os XP existentes no mapa até a canoa, a 630 pixels/s;
a experiência é recebida quando cada XP chega. As outras duram seis segundos.
Fúria dá +50% dano, +50% frequência e +20% velocidade; Intangível protege de
todo dano; Perfurante faz novas lanças atravessarem peixes e chefes vulneráveis,
causando 100% do dano no primeiro alvo, 70% no segundo, 50% no terceiro e 20%
em todos os seguintes. Cada lança acerta cada alvo apenas uma vez e segue até
a borda ou o fim de sua duração. O dano base é fixado no disparo.
Efeitos diferentes combinam; repetir uma carta renova o tempo sem acumular bônus.
Cartas flutuam e recebem um brilho de cima para baixo. Desaparecem em 30 segundos,
piscando a cada meio segundo nos últimos cinco. Pausas e escolhas de melhorias
congelam efeitos e animações. Ícones na parte inferior mostram o tempo restante.
Na **Sala de treino**, **F9** invoca as quatro cartas para experimentar.
**Ctrl+1** ativa Ímã, **Ctrl+2** Fúria, **Ctrl+3** Intangível e **Ctrl+4** Perfurante,
diretamente, mesmo com os drops desligados. Também há botões na guia Treino.
Pause com ESC e ative **Habilitar cartas** na guia Treino para habilitar drops:
peixes usam as mesmas chances da partida e chefões deixam uma carta garantida.
Pintado tem chance de carta de 5% no início, pacu de 5% e dourado de 10%.
As chances diminuem linearmente até 1%, 2% e 5%, respectivamente, aos quatro
minutos e permanecem nesses valores depois. Sorte multiplica essas chances.
A opção começa desligada e volta a ficar desligada ao reiniciar o treino.

Protótipo 2D em Godot 4.7.2. O título é provisório.
O ranking global usa uma planilha privada com Apps Script. Cadastro de nickname
único, edição do nome, consulta manual e envio apenas de novos recordes pessoais
estão preparados. Para ativar, publique o backend e configure `online.cfg` conforme
o [guia de configuração](docs/ranking-global-configuracao.md). O primeiro cadastro
exige conexão com o serviço; depois disso, recordes offline aguardam sincronização.
Sem a URL de implantação, o cadastro global permanece indisponível.
Fonte global: Perfect DOS VGA 437 Win, incluindo interface e números de dano.
Créditos e autorização do autor preservados em `assets/fonts`.

## Executar no Windows

A abertura verifica versões publicadas e permite **Jogar offline**.
A instalação automática integrada para Windows consulta as
[Releases do projeto](https://github.com/emanuel-bm/pesca-mortal/releases).
Na release 0.4.0, baixe e execute `pesca-mortal-windows-v0.4.0.exe` diretamente. Consulte
[distribuição e atualizações](docs/atualizacoes.md).

Os formatos e o comando para preparar Windows, macOS Apple Silicon e Linux
estão no [guia de distribuição desktop](docs/distribuicao-desktop.md).
A geração dos arquivos não cria uma release nem envia arquivos ao GitHub.

## Notas de atualização e publicação de releases

**Sempre que publicarmos uma nova release, devemos atualizar as notas de
atualização.** A descrição da Release no GitHub é a fonte oficial exibida
pelo botão **?** ao lado da versão na tela inicial do jogo.

O padrão das notas é uma introdução de duas ou três frases, seguida de seções
por inimigo, habilidade ou sistema alterado. Cada seção pode ter uma explicação
curta e bullets objetivos. Mudanças de atributos devem apresentar **valor
anterior → valor novo**, com unidade e condições; recursos novos apresentam
seus valores iniciais. Não incluir instruções de download, nomes de arquivos,
comandos de instalação, detalhes técnicos ou relatórios de testes nas notas.

1. Antes de exportar, atualizar a versão em `project.godot` e escrever as notas
   em `docs/releases/<versão>.md`, descrevendo as novidades, correções e ajustes
   dessa versão para os jogadores. Executar
   `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/sync_release_notes.ps1 -IncludeCurrentVersion`
   para incluir a lista de versões e apenas as notas dessa versão na build offline.
2. Incluir essas notas no corpo da nova Release do GitHub, com título e tag
   correspondentes à versão publicada. Não publicar uma release sem notas.
3. Depois de publicar, executar
   `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/sync_release_notes.ps1`
   e incluir `assets/release_notes.json` atualizado no próximo commit. Esse
   arquivo inclui a lista de versões e apenas o conteúdo da última atualização.
4. Conferir a nova versão na tela **Notas de atualização** do jogo.

A tela abre a última atualização e mostra as versões e datas na lista à
esquerda. Apenas a última nota acompanha a build; as anteriores são baixadas
ao selecionar e ficam salvas para leitura offline. A lista pública de releases
é atualizada ao abrir a tela, com intervalo de cinco minutos entre consultas.
A API de listagem do GitHub inclui os corpos das releases na resposta; o jogo
descarta esses corpos e mantém apenas versão e data, buscando a nota selecionada
pelo endpoint de tag. Rascunhos e pré-releases não aparecem.

Abra `Jogar.bat`. A engine portátil está em `.tools/godot` nesta máquina.
Para editar, abra `Abrir-editor.bat` ou importe `project.godot` em Godot 4.7.2.
A sala de treino está disponível no menu do jogo para configurar inimigos e atributos.
Os atalhos dependem da engine portátil local; não são um pacote de distribuição.

## Controles

Perder o foco pausa a partida e suspende o áudio. Vídeos em picture-in-picture
e notificações sobre o jogo não pausam a partida enquanto o jogo mantém o foco.
Ao retornar o foco, use **Continuar** para retomar.
Cada tela de melhoria aceita uma única escolha por teclado ou mouse, mesmo
durante a perda de foco ou quando há vários níveis acumulados.

Validação: `res://scripts/test_focus_pause.gd` verifica pausa, áudio e retomada;
`res://scripts/test_upgrade_single_selection.gd` verifica escolhas repetidas,
perda de foco e botões de telas anteriores com níveis acumulados. O teste
`res://scripts/test_fullscreen_focus.gd`, executado sem `--headless`, alterna
os modos de janela e verifica áudio, Voltar e Continuar.

O pacu voltou como inimigo separado do dourado: usa `assets/pacu-v4.png`,
tem 80 HP base escalados pelo tempo, 30 de dano, 10 XP e velocidade de 80 pixels/s,
sem arrancada. Compartilha a liberação do dourado. **F11** invoca 10 pacus no treino.
Um dano de pacu bloqueia novas ativações de cartas por cinco segundos de jogo;
outro dano renova o tempo. Cartas no chão e ícones dos efeitos ficam cinza durante
o bloqueio. Cartas não são consumidas ao tocar nelas enquanto bloqueadas, mas
continuam expirando normalmente. O golpe remove todos os efeitos de cartas ativos,
incluindo a atração do Ímã; as cartas bloqueadas ficam em cinza escuro, sem brilho. Invulnerabilidade
e Intangível impedem o bloqueio quando impedem o dano. Pausas congelam o tempo.

O dourado usa o sprite `assets/dourado-v1.png`, com 46 pixels de comprimento e
colisão pelo contorno. Aproxima-se a 100 pixels/s, anuncia por 1,1 segundo uma
arrancada em direção fixa, mirando a posição prevista da canoa após 0,5 segundo
com sua velocidade atual (incluindo melhorias). A previsão é calculada uma vez
no início do aviso e limitada à arena. Avança a 1.400 pixels/s por 159,705 pixels
antes dos buffs por minuto e por chefão. Emite partículas de água durante o preparo
e ao longo de todo o percurso. Inicia o preparo a até 70% do alcance
atual da arrancada; esse limite cresce junto com os buffs. Descansa
por 0,75 segundo. Depois do descanso, pode preparar outra arrancada assim que
estiver dentro do alcance de preparo, sem cooldown adicional. Tem 200 de vida base, 15 de dano e dá
20 XP; recebe +8% de vida, velocidade de nado e alcance da arrancada por minuto, +4% de dano, além de +5% por chefão no infinito. A velocidade da arrancada permanece fixa.
Na sala de treino, **F10** invoca 10 dourados ao redor da canoa.

Distribuição por surgimento automático (um único sorteio):

| Etapa | Piranha | Pintado | Pacu | Dourado |
| --- | --- | --- | --- | --- |
| Antes de 1 minuto | 100% | 0% | 0% | 0% |
| A partir de 1 minuto | 80% | 20% | 0% | 0% |
| Primeiro chefão apareceu | 70% | 30% | 0% | 0% |
| Segunda horda no infinito | 50% | 15% | 25% | 10% |

A última distribuição permanece até o fim da partida. Invocações manuais no
treino continuam gerando somente o tipo solicitado.

- WASD ou setas: movimentar.
- Ataque automático ao inimigo mais próximo.
- Colete quadrados verdes para ganhar experiência.
- Escolha melhorias com mouse ou teclas 1, 2 e 3.
- Na escolha de melhorias, a tabela à direita mostra atributos atuais.
  Passe o mouse ou dê foco a uma opção para ver o valor atual e a prévia em verde.
  As opções aparecem em cartas lado a lado com os valores atual e próximo. A prévia só aplica a mudança ao escolher; velocidade pode aumentar sem teto.
- ESC: pausar ou continuar. Ao perder o foco da janela, a partida pausa; voltar à janela mantém a pausa até continuar.

Configurações de tela estão disponíveis no menu inicial e no menu de pausa.
Escolha resolução de janela ou tela cheia e clique em Aplicar e salvar.
As preferências ficam em `user://display.cfg`; a janela inicial é limitada à
área útil do monitor. A interface centraliza e escala ao redimensionar a janela.
Resoluções disponíveis até QHD (2560 × 1440) e 4K (3840 × 2160).
O contador de FPS pode ser ativado nas configurações e aparece no canto superior direito.
O FPS é limitado a 360 por padrão, com VSync desativado para não acompanhar a frequência
do monitor. O slider de FPS e o campo numérico à direita permitem salvar qualquer limite
inteiro entre 60 e 360 FPS.
Tela cheia utiliza a resolução do monitor; em janela, tamanhos maiores que a área útil são limitados.

A chegada do Minhocão mostra um aviso roxo e um breve tremor da arena.
Sobreviva por cinco minutos. O Minhocão aparece e as hordas continuam surgindo
durante a luta. Derrotar o chefe encerra a partida com vitória.

## Escopo

Uma arena delimitada, quatro tipos de peixes, um chefe perseguidor,
cinco melhorias (sem limite de escolhas; velocidade sem teto), dano com invulnerabilidade
temporária e knockback para longe do atacante, pausa, derrota, vitória e reinício.
Vida máxima inicial de 100; dano base de piranha 10, pintado 20, pacu 30,
dourado 15 e Minhocão 40 (contato), 60 (emergência) e 80 (investida).
Pintados têm 200 HP base, antes dos buffs por minuto e por chefão derrotado.
Minhocão com 32.000 de vida; somente o chefe exibe barra de vida.
Alterna mergulho de 0,5 s e aviso de emergência de 0,75 s,
emergência, exposição por 3 s e investida em linha anunciada por 0,9 s.
A investida atravessa o trajeto em 0,5 s; movimento à superfície de 54.
Enterrado, não recebe dano nem atrai disparos. Emergência causa 60 de dano
na área anunciada; contato mantém a invulnerabilidade de 0,8 s do jogador.
Velocidade inicial do jogador: 190; melhorias de 10%, sem teto.
Peixes usam sua própria velocidade, sem limite baseado na velocidade do jogador.
Piranhas e pacus se movem a 125 pixels/s, pintados a 80 pixels/s e dourados
a 100 pixels/s. A cada minuto completo de jogo, os peixes vivos recebem
+8% de vida atual, vida máxima e velocidade, e +4% de dano, de forma multiplicativa.
Novos peixes herdam todos os minutos completos: vida e velocidade base × 1,08 elevado
ao número de minutos; dano base × 1,04 elevado ao número de minutos.
A arrancada do dourado mantém 1.400 pixels/s; seu alcance cresce +8% por minuto,
sem teto. A investida avança a cada frame até esgotar a distância restante,
sem calcular duração; dobrar o alcance naturalmente dobra o tempo do percurso.
No infinito, os +5% por chefão morto se multiplicam com esses bônus. Chefões
não recebem o bônus por minuto. XP, tamanho e tempos de aviso não aumentam.
O deslocamento normal de todos os inimigos tem teto de velocidade base × 1,08^10.
Minhocão: base de 100 pixels/s na superfície; Pai do Mato: base de 120 pixels/s.
O jogador continua sem teto. Ataques especiais usam regras próprias: arrancada do
dourado com velocidade fixa e alcance sem teto, investida do Minhocão a 1.400 pixels/s e
tronco do Pai do Mato com velocidade fixa. Tempos de aviso não escalam com buffs.
No infinito, vida atual e máxima do Minhocão crescem 10% por chefão derrotado;
novos Minhocões herdam 32.000 × 1,10 elevado ao total de chefões derrotados.
O Minhocão aguarda submerso por 0,5 segundo antes de mostrar o aviso, sem fase
oculta de rastreamento. Avisos mantêm sua variação de ±30%; a investida percorre
até 500 pixels, encurtados nas bordas, controlada por distância restante.
Emergência produz ondas e partículas; investida deixa rastro e onda no ponto final.
Melhorias de vida máxima e dano de ataque aumentam o valor atual em 20% por escolha, sem teto de evolução.
Valores exibidos são arredondados para inteiros; cálculos mantêm a precisão.
O alcance de coleta de XP é fixo em 180, sem melhoria e oculto nos atributos do pescador.
Aprendizado aumenta o bônus de ganho de XP em 20 pontos percentuais por escolha, sem limite máximo.
Experiência base: piranha 1 XP, pintado 5 XP, pacu 10 XP, dourado 20 XP e chefão 100 XP.
Cristais de maior valor aparecem maiores e concedem todo o XP ao serem coletados.
Projéteis são lanças orientadas pelo disparo. Personagem, canoa, Minhocão,
piranhas, pintados e água usam pixel art gerada com ImageGen.
Piranhas mantêm 26 pixels de comprimento e pintados 88 pixels. Colisões dos peixes
usam contornos extraídos da transparência, com o mesmo recorte e espelhamento
do desenho. A arena recebe água em mosaico, e o personagem original foi
preservado numa canoa de madeira; o sprite original segue em `assets/player.png`.
Cada intervalo de surgimento gera dois inimigos (dobro da versão inicial).
Ao esgotar todas as melhorias, novos níveis restauram 25 de vida.
Há limite de 1.000 inimigos simultâneos.
Áudio: gravação de haste de bambu para lançamento da lança (qubodup, CC0),
com créditos em `assets/audio/CREDITS.md`; morte e dano usam impactos secos sintetizados.
Um som por rajada; mortes simultâneas têm intervalo mínimo de 65 ms.
**Correnteza sombria** toca em loop no menu e no início da partida, sem reiniciar
ao começar a jogar. A faixa calma faz um fade de quatro segundos: começa
dois segundos antes do primeiro chefe e termina dois segundos depois.
No surgimento do chefe, seu rugido de dois segundos toca e **Correnteza em fúria**
começa do zero, chegando ao volume configurado quatro segundos depois.
As faixas se sobrepõem nos dois segundos iniciais após o surgimento.
A faixa eletrônica permanece até o fim da partida,
inclusive após derrotar chefes, durante pausas e escolhas de melhorias.
Novos chefes não reiniciam a música. Voltar ao menu ou reiniciar a partida restaura
a faixa calma. Ambas têm 30 segundos em loop contínuo.
As configurações de áudio têm cinco controles: **Geral**, **Música**, **Chefões**,
**Inimigos** e **Personagem**. Geral afeta todos os sons; Música controla as
trilhas; Chefões controla os sons do Minhocão e do Pai do Mato. Inimigos controla
somente peixes mergulhando. Personagem controla lança, dano recebido, cartas e
subida de nível.
O primeiro ataque de cada Minhocão sempre segue a sequência de marcação,
aviso e emergência do solo; após a primeira exposição, os ataques voltam a
ser escolhidos aleatoriamente. Cada emergência toca um impacto de terra/água,
e cada investida em linha toca um som grave de deslocamento de ar.
Cada nova onda de chefes anuncia o surgimento com um rugido, sem sobrepor
sons de chefes que aparecem juntos nem reiniciar a música de batalha.
Composições reproduzíveis em `assets/audio/compose_theme.py` e
`assets/audio/compose_battle_theme.py`; detalhes nos créditos.
Acertos mostram o dano acima do alvo, incluindo o golpe final; números sobem
e desaparecem em 0,7 s, acompanhando a câmera e pausando com a partida.
Arte, identidade regional e balanceamento final ficam para a próxima etapa.

## Verificação

Importação headless e verificações automatizadas dos sistemas do jogo:

```powershell
& '.\.tools\godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --editor --quit
& '.\.tools\godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script res://scripts/test_layout.gd
& '.\.tools\godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script res://scripts/test_combat.gd
& '.\.tools\godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script res://scripts/test_minhocao.gd
```

Essas verificações não substituem jogar a partida completa e ajustar dificuldade.
Antes de enviar aos avaliadores, exportar uma build Windows independente,
testar em outra máquina e preparar vídeo, identidade visual e documentação.

Godot é distribuído sob licença MIT. Consulte `GODOT-LICENSE.txt`.

Recordes globais e pessoais são separados por versão competitiva X.Y; patches Z mantêm a classificação. O botão **Lendas** abre os campeões e os rankings anteriores, com até 100 jogadores por modo no arquivo global. Veja [a configuração e publicação de Lendas](docs/lendas.md) para atualizar o Apps Script da planilha existente e encerrar uma versão ao publicar outro X.Y.

A arena aquática possui reflexos procedurais em movimento, inspirados no vídeo
fornecido como referência, mantendo o tom escuro da água. Duas camadas de
reflexos se deformam, e a canoa deixa ondulações; a pausa congela a superfície.


## Desempenho no fim da partida

As colisões de lanças usam uma grade espacial de células de 128 unidades, reconstruída após o movimento dos inimigos. Cada lança consulta apenas células vizinhas; a colisão de silhueta e a ordem dos alvos são preservadas. Inimigos fora da tela continuam sendo simulados e mostrados no minimapa, mas seus sprites não são desenhados. Cartas no chão aparecem no minimapa como pequenos cartões dourados, inclusive fora da tela; os marcadores desaparecem ao coletar ou expirar a carta. Lanças, XP e números fora da tela também são descartados no desenho.

Benchmark reproduzível: `scripts/benchmark_late.gd`, seed 417, 501 inimigos incluindo chefe, 300 lanças, 30 atualizações. Na máquina de desenvolvimento, a atualização de CPU caiu de 158,91 ms para 12,79 ms. Esse teste isolado não mede FPS total nem custo da GPU. `scripts/test_performance.gd` compara mil consultas com a busca completa e verifica que volume geral zero ou efeito individual zero impede reprodução; zerar interrompe um som já em andamento.
