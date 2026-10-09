# Pesca Mortal — protótipo

Beta atual: **0.2.1**. Código, arte, áudio, scripts de servidor e testes estão
incluídos no projeto. Ferramentas locais, caches e builds exportadas ficam
fora do Git; pacotes para jogar são distribuídos pelas Releases.

O menu oferece **Modo infinito** e **Modo por chefões**. O modo por chefões
mantém o confronto aos cinco minutos e termina ao vencer o Minhocão.
No infinito, o primeiro chefão aparece aos quatro minutos. Depois, novas ondas
aparecem a cada dois minutos, com dois chefões na segunda, três na terceira
e assim por diante, sem remover chefões ainda vivos. Cada chefão abatido
multiplica HP, dano e velocidade dos inimigos por 1,05, de forma acumulativa,
atingindo os atuais e os próximos. Tamanho e XP dos peixes não mudam com o buff.
O contador de eliminações inclui chefões no modo infinito.

O histórico do infinito é local, em `user://endless_runs.json`. O ranking ordena
por tempo ativo de sobrevivência, depois por eliminações. Pausas, configurações
e escolhas de melhorias não contam como sobrevivência. Morte, volta ao menu,
reinício e fechamento encerram a run e a registram uma única vez; partidas do
modo por chefões e testes de nível 30 não entram no ranking. O recorde aparece
no menu e o botão Histórico abre a lista completa.

A [pesquisa sobre habilidades e cartas](docs/pesquisa-habilidades.md) descreve
as referências. As [regras das cartas](docs/cartas-em-discussao.md) estão implementadas:
piranhas têm 0,25% de chance de drop, pintados 1,25% e chefões do infinito 100%.
Cada drop sorteia igualmente Ímã, Fúria, Intangível ou Perfurante. Coletar ativa
a carta: Ímã atrai todos os XP existentes no mapa até a canoa, a 630 pixels/s;
a experiência é recebida quando cada XP chega. As outras duram seis segundos.
Fúria dá +50% dano, +50% frequência e +20% velocidade; Intangível protege de
todo dano; Perfurante faz novas lanças atravessarem os alvos consumindo seu saldo
de dano pela vida atual de cada alvo, até esgotar o saldo ou atingir a borda.
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
Na release 0.2.1, baixe e execute `pesca-mortal-windows-v0.2.1.exe` diretamente. Consulte
[distribuição e atualizações](docs/atualizacoes.md).

Os formatos e o comando para preparar Windows, macOS Apple Silicon e Linux
estão no [guia de distribuição desktop](docs/distribuicao-desktop.md).
A geração dos arquivos não cria uma release nem envia arquivos ao GitHub.

Abra `Jogar.bat`. A engine portátil está em `.tools/godot` nesta máquina.
Para editar, abra `Abrir-editor.bat` ou importe `project.godot` em Godot 4.7.2.
A sala de treino está disponível no menu do jogo para configurar inimigos e atributos.
Os atalhos dependem da engine portátil local; não são um pacote de distribuição.

## Controles

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
durante a luta. Derrote o chefe para vencer.

## Escopo

Uma arena delimitada, dois inimigos comuns, um chefe perseguidor,
cinco melhorias (sem limite de escolhas; velocidade sem teto), dano com invulnerabilidade
temporária e knockback para longe do atacante, pausa, derrota, vitória e reinício.
Vida máxima inicial de 50; dano comum de 10, resistente de 15 e chefe de 25.
Minhocão com 32.000 de vida; somente o chefe exibe barra de vida.
Alterna mergulho de 0,6 s, marca que acompanha por 0,375 s e trava por 0,75 s,
emergência, exposição por 3 s e investida em linha anunciada por 0,9 s.
A investida atravessa o trajeto em 0,5 s; movimento à superfície de 54.
Enterrado, não recebe dano nem atrai disparos. Emergência causa 25 de dano
na área anunciada; contato mantém a invulnerabilidade de 0,8 s do jogador.
Velocidade inicial do jogador: 190; melhorias de 4%, sem teto.
Peixes usam sua própria velocidade, sem limite baseado na velocidade do jogador.
Resistentes se movem a 78; perseguidores começam a 126. Todas as velocidades
de movimento aumentaram 20% em relação à versão anterior.
Velocidades do jogador, dos peixes e dos chefões crescem sem teto de progressão. Movimentos na superfície e investidas do Minhocão recebem o multiplicador completo dos buffs; os tempos dos avisos continuam iguais.
Melhorias de vida máxima e dano de ataque aumentam o valor atual em 20% por escolha.
Valores exibidos são arredondados para inteiros; cálculos mantêm a precisão.
Experiência por inimigo escala com sua área: pequenos dão 1 XP e laranjas 3 XP.
Cristais de maior valor aparecem maiores e concedem todo o XP ao serem coletados.
Projéteis são lanças orientadas pelo disparo. Personagem, canoa, Minhocão,
piranhas, pintados e água usam pixel art gerada com ImageGen.
Piranhas mantêm 26 pixels de comprimento e pintados 88 pixels. Colisões dos peixes
usam contornos extraídos da transparência, com o mesmo recorte e espelhamento
do desenho. A arena recebe água em mosaico, e o personagem original foi
preservado numa canoa de madeira; o sprite original segue em `assets/player.png`.
Cada intervalo de surgimento gera dois inimigos (dobro da versão inicial).
Ao esgotar todas as melhorias, novos níveis restauram 25 de vida.
Há limite de 520 inimigos simultâneos.
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

As colisões de lanças usam uma grade espacial de células de 128 unidades, reconstruída após o movimento dos inimigos. Cada lança consulta apenas células vizinhas; a colisão de silhueta e a ordem dos alvos são preservadas. Inimigos fora da tela continuam sendo simulados e mostrados no minimapa, mas seus sprites não são desenhados. Lanças, XP e números fora da tela também são descartados no desenho.

Benchmark reproduzível: `scripts/benchmark_late.gd`, seed 417, 501 inimigos incluindo chefe, 300 lanças, 30 atualizações. Na máquina de desenvolvimento, a atualização de CPU caiu de 158,91 ms para 12,79 ms. Esse teste isolado não mede FPS total nem custo da GPU. `scripts/test_performance.gd` compara mil consultas com a busca completa e verifica que volume geral zero ou efeito individual zero impede reprodução; zerar interrompe um som já em andamento.
