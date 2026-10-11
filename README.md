# Pesca Mortal — protótipo

Beta atual: **0.3.2**. Código, arte, áudio, scripts de servidor e testes estão
incluídos no projeto. Ferramentas locais, caches e builds exportadas ficam
fora do Git; pacotes para jogar são distribuídos pelas Releases.

O menu oferece **Modo infinito** e **Modo por chefões**. O modo por chefões
mantém o confronto aos cinco minutos e continua após vencer o Minhocão,
liberando pacus e dourados. O próximo chefão ainda não foi implementado.
No infinito, o primeiro chefão aparece aos três minutos. Depois, novas ondas
aparecem a cada dois minutos, com dois chefões na segunda, três na terceira
e assim por diante, sem remover chefões ainda vivos. Cada chefão abatido
multiplica HP, dano e velocidade dos inimigos por 1,05, de forma acumulativa,
atingindo os atuais e os próximos. Tamanho e XP dos peixes não mudam com o buff.
O contador de eliminações inclui chefões no modo infinito.
Cada chefão deixa uma ventrecha gigante de 112 pixels (8 vezes a comum),
com 100 XP base, sujeitos ao bônus de experiência. No modo por chefões,
o drop pode ser coletado, pois a partida continua após derrotar o chefe.
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
Cada drop sorteia igualmente Ímã, Fúria, Intangível ou Perfurante. Coletar ativa
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
Na release 0.3.2, baixe e execute `pesca-mortal-windows-v0.3.2.exe` diretamente. Consulte
[distribuição e atualizações](docs/atualizacoes.md).

Os formatos e o comando para preparar Windows, macOS Apple Silicon e Linux
estão no [guia de distribuição desktop](docs/distribuicao-desktop.md).
A geração dos arquivos não cria uma release nem envia arquivos ao GitHub.

Abra `Jogar.bat`. A engine portátil está em `.tools/godot` nesta máquina.
Para editar, abra `Abrir-editor.bat` ou importe `project.godot` em Godot 4.7.2.
A sala de treino está disponível no menu do jogo para configurar inimigos e atributos.
Os atalhos dependem da engine portátil local; não são um pacote de distribuição.

## Controles

O pacu voltou como inimigo separado do dourado: usa `assets/pacu-v4.png`,
tem 80 HP base escalados pelo tempo, 30 de dano, 4 XP e velocidade de 80 pixels/s,
sem arrancada. Compartilha a liberação do dourado. **F11** invoca 10 pacus no treino.
Um dano de pacu bloqueia novas ativações de cartas por cinco segundos de jogo;
outro dano renova o tempo. Cartas no chão e ícones dos efeitos ficam cinza durante
o bloqueio. Cartas não são consumidas ao tocar nelas enquanto bloqueadas, mas
continuam expirando normalmente. Efeitos já ativos continuam; invulnerabilidade
e Intangível impedem o bloqueio quando impedem o dano. Pausas congelam o tempo.

O dourado usa o sprite `assets/dourado-v1.png`, com 46 pixels de comprimento e
colisão pelo contorno. Aproxima-se a 100 pixels/s, anuncia por 1,1 segundo uma
arrancada em direção fixa, mirando a posição prevista da canoa após 0,5 segundo
com sua velocidade atual (incluindo melhorias). A previsão é calculada uma vez
no início do aviso e limitada à arena. Avança a 756 pixels/s por 0,21125 segundo (159,705 pixels
antes dos buffs por minuto e por chefão). Inicia o preparo a até 70% do alcance
atual da arrancada; esse limite cresce junto com os buffs. Descansa
por 0,75 segundo. Ao terminar cada arrancada, sorteia um cooldown de 1 a 3
segundos antes de poder preparar outra; o descanso conta dentro desse tempo.
Depois do descanso, volta a nadar enquanto aguarda. Tem 200 de vida base, 15 de dano e dá
8 XP; recebe os mesmos buffs acumulativos dos demais.
Na sala de treino, **F10** invoca 10 dourados ao redor da canoa.

Distribuição por surgimento automático (um único sorteio):

| Etapa | Piranha | Pintado | Pacu | Dourado |
| --- | --- | --- | --- | --- |
| Antes de 1 minuto | 100% | 0% | 0% | 0% |
| A partir de 1 minuto | 80% | 20% | 0% | 0% |
| Primeiro chefão apareceu | 70% | 30% | 0% | 0% |
| Segunda horda no infinito ou primeiro chefe morto no modo por chefões | 50% | 15% | 25% | 10% |

A última distribuição permanece até o fim da partida. Invocações manuais no
treino continuam gerando somente o tipo solicitado.

- WASD ou setas: movimentar.
- Ataque automático ao inimigo mais próximo.
- Colete quadrados verdes para ganhar experiência.
- Escolha melhorias com mouse ou teclas 1, 2 e 3.
- Na escolha de melhorias, a tabela à direita mostra atributos atuais.
  Passe o mouse ou dê foco a uma opção para ver o valor atual e a prévia em verde.
  A prévia só aplica a mudança ao escolher; velocidade pode aumentar sem teto.
- ESC: pausar ou continuar.

Configurações de tela estão disponíveis no menu inicial e no menu de pausa.
Escolha resolução de janela ou tela cheia e clique em Aplicar e salvar.
As preferências ficam em `user://display.cfg`; a janela inicial é limitada à
área útil do monitor. A interface centraliza e escala ao redimensionar a janela.
Resoluções disponíveis até QHD (2560 × 1440) e 4K (3840 × 2160).
O contador de FPS pode ser ativado nas configurações e aparece no canto superior direito.
Tela cheia utiliza a resolução do monitor; em janela, tamanhos maiores que a área útil são limitados.

Sobreviva por cinco minutos. O Minhocão aparece e as hordas continuam surgindo
durante a luta. Derrotar o chefe libera pacus e dourados e a partida continua.

## Escopo

Uma arena delimitada, quatro tipos de peixes, um chefe perseguidor,
cinco melhorias (sem limite de escolhas; velocidade sem teto), dano com invulnerabilidade
temporária e knockback para longe do atacante, pausa, derrota, vitória e reinício.
Vida máxima inicial de 100; dano base de piranha 10, pintado 20, pacu 30,
dourado 15 e Minhocão 60.
Pintados têm 200 HP base, antes dos buffs por minuto e por chefão derrotado.
Minhocão com 32.000 de vida; somente o chefe exibe barra de vida.
Alterna mergulho de 0,6 s, marca que acompanha por 0,375 s e trava por 0,75 s,
emergência, exposição por 3 s e investida em linha anunciada por 0,9 s.
A investida atravessa o trajeto em 0,5 s; movimento à superfície de 54.
Enterrado, não recebe dano nem atrai disparos. Emergência causa 60 de dano
na área anunciada; contato mantém a invulnerabilidade de 0,8 s do jogador.
Velocidade inicial do jogador: 190; melhorias de 4%, sem teto.
Peixes usam sua própria velocidade, sem limite baseado na velocidade do jogador.
Piranhas se movem a 125 pixels/s, pintados e pacus a 80 pixels/s e dourados
a 100 pixels/s. A cada minuto completo de jogo, todos os peixes vivos recebem
+10% de vida atual, vida máxima, dano e velocidade, de forma multiplicativa.
Novos peixes herdam todos os minutos completos: atributos base × 1,1 elevado
ao número de minutos. Isso substitui o antigo crescimento linear da vida.
No infinito, os +5% por chefão morto se multiplicam com esse bônus. Chefões
não recebem o bônus por minuto. XP, tamanho e tempos de aviso não aumentam;
a velocidade da arrancada do dourado recebe o multiplicador dos atributos.
Velocidades do jogador, dos peixes e dos chefões crescem sem teto de progressão. Movimentos na superfície e investidas do Minhocão recebem o multiplicador completo dos buffs; os tempos dos avisos continuam iguais.
Melhorias de vida máxima e dano de ataque aumentam o valor atual em 20% por escolha.
Valores exibidos são arredondados para inteiros; cálculos mantêm a precisão.
Experiência base: piranha 1 XP, pintado 5 XP, pacu 4 XP, dourado 8 XP e chefão 100 XP.
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
O controle **Música** nas configurações
ajusta seu volume independentemente dos efeitos; **Geral** também afeta a trilha.
**Rugido do Minhocão** tem volume próprio e botão Ouvir nas configurações.
O primeiro ataque de cada Minhocão sempre segue a sequência de marcação,
aviso e emergência do solo; após a primeira exposição, os ataques voltam a
ser escolhidos aleatoriamente. Cada emergência toca um impacto de terra/água,
e cada investida em linha toca um som grave de deslocamento de ar. Esses efeitos
têm controles próprios de volume e prévia nas configurações.
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

A arena aquática possui reflexos procedurais em movimento, inspirados no vídeo
fornecido como referência, mantendo o tom escuro da água. Duas camadas de
reflexos se deformam, e a canoa deixa ondulações; a pausa congela a superfície.


## Desempenho no fim da partida

As colisões de lanças usam uma grade espacial de células de 128 unidades, reconstruída após o movimento dos inimigos. Cada lança consulta apenas células vizinhas; a colisão de silhueta e a ordem dos alvos são preservadas. Inimigos fora da tela continuam sendo simulados e mostrados no minimapa, mas seus sprites não são desenhados. Cartas no chão aparecem no minimapa como pequenos cartões dourados, inclusive fora da tela; os marcadores desaparecem ao coletar ou expirar a carta. Lanças, XP e números fora da tela também são descartados no desenho.

Benchmark reproduzível: `scripts/benchmark_late.gd`, seed 417, 501 inimigos incluindo chefe, 300 lanças, 30 atualizações. Na máquina de desenvolvimento, a atualização de CPU caiu de 158,91 ms para 12,79 ms. Esse teste isolado não mede FPS total nem custo da GPU. `scripts/test_performance.gd` compara mil consultas com a busca completa e verifica que volume geral zero ou efeito individual zero impede reprodução; zerar interrompe um som já em andamento.
