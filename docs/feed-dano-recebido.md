# Feed de dano recebido

Status: definição confirmada e implementada.

## Decisões confirmadas

- Uma entrada por golpe que efetivamente reduziu a vida, inclusive golpes consecutivos do mesmo agressor.
- Cada entrada mostra o sprite, o nome do agressor e o dano efetivamente recebido.
- A entrada mais recente aparece em cima e empurra as anteriores para baixo.
- No máximo cinco entradas visíveis; a sexta remove a mais antiga.
- Cada entrada dura quatro segundos e desaparece suavemente.
- Golpes bloqueados, esquivados ou anulados por invulnerabilidade não geram entrada.

## Apresentação e ciclo de vida

- Cartões compactos com fundo escuro abaixo do minimapa, entrada suave pela direita e deslocamento suave dos anteriores para baixo.
- O tempo e as animações congelam enquanto o jogo estiver pausado ou na escolha de melhorias.
- O feed fica oculto no fim da partida e é limpo ao iniciar outra.
- O golpe fatal não gera entrada: sua informação já aparece na tela de morte.
- No treino com morte impedida, um golpe de 30 contra 10 de vida mostra 9, pois resta um ponto de vida. Sem perda de vida, não há entrada.
- O tronco arremessado aparece no feed como “Tronco”, com o retrato do próprio tronco. Outros ataques do Pai do Mato mostram o chefe. As estatísticas e a tela de morte conservam a atribuição ao Pai do Mato.
- Em janelas baixas, os cartões reduzem de tamanho para caber abaixo do minimapa.
- Apenas a largura tem 60% do valor original (162 em vez de 270). Altura, texto e retratos mantêm o tamanho original, com a borda direita encostada na tela e sem cantos arredondados desse lado. Textos que não couberem recebem reticências.
- Todos os retratos do feed são invertidos horizontalmente, fazendo os peixes olharem para a esquerda.

## Referências no jogo

- `scripts/game.gd`: `receive_hit` concentra o recebimento de dano; `show_fatal_hit` já monta retratos dos agressores.
- Troncos arremessados conservam o Pai do Mato como agressor.
- O treino pode impedir a morte e manter o jogador com um ponto de vida.

## Validação

- `scripts/test_incoming_damage_feed.gd`: origem, retratos, ordem, invulnerabilidade, perda real de vida no treino, pausa, limite de entradas, desaparecimento, golpe fatal, reinício e layout em janela pequena. Passou sem interface e com renderização.
- Prévia visual conferida em `.tools/incoming-damage-preview.png`.
- O conteúdo separado para este commit foi validado em uma cópia isolada: `test_incoming_damage_feed.gd` e o teste original `test_hit_feedback.gd` passaram. Alterações de balanceamento e de outros trabalhos no diretório local não fazem parte deste commit.
