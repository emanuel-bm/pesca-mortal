# Pai do Mato

Implementação em `scripts/pai_do_mato.gd`, integrada ao combate, aos projéteis,
à interface, ao histórico de morte e à sala de treino.

## Ondas

No modo normal (Jogar), ondas 1–5: 1, 2, 3, 4 e 5 Minhocões.
Onda 6: um Pai do Mato. Onda 7: dois. Onda 8: três, crescendo um por onda.
O primeiro confronto ocorre aos três minutos, com intervalo de dois minutos.

Na edição especial Boss Rush, há somente duas hordas: um Minhocão aos 2:00
e um Pai do Mato 30 segundos após a morte do Minhocão. Enquanto o Minhocão estiver
vivo, o segundo chefe não aparece. Derrotar o Pai do Mato encerra a partida com vitória.

## Atributos e ataques

150.000 HP base: 7,5 vezes os 20.000 do Minhocão. Contato base: 60 de dano.
Vida, velocidade normal e dano recebem +20%, +20%, +10% e depois +6% da
base por minuto completo, em todos os modos, sem composição. Vida atual preserva a fração restante.
Nasce com os bônus do tempo da partida.
Derrotar chefões não aumenta atributos. Pode ser atingido em qualquer fase.
Deslocamento base: 120 pixels/s, sem teto; aos 20 minutos chega a 302,4 pixels/s.

Escolhe o ataque pela distância, sem sorteio ou alternância: mãozona a até 260 pixels do centro do chefe; acima disso, tronco somente quando o centro do chefe está dentro da tela. Fora da tela, continua se aproximando.

- **Mãozona:** aviso de 1,2 segundo, com marca a no máximo 160 pixels do corpo. O deslocamento relativo e o ângulo são fixados no início do preparo; o chefe continua perseguindo durante o preparo e o impacto, levando a marca junto sem girá-la. A mão foi reduzida à metade do tamanho anterior.
  Um único impacto de 150 de dano base, respeitando invulnerabilidade e
  Intangível. A palma, o polegar, os quatro dedos e os espaços entre eles
  formam um polígono único, compartilhado pelo desenho e pela colisão.
- **Tronco:** aviso de meio segundo, seguido por arremesso a velocidade constante de aproximadamente 1.846 pixels/s. A duração é a distância até o pouso dividida pela velocidade; 600 pixels levam 0,325 segundo
  em linha reta na direção marcada. Para 30% além da posição do pescador
  travada no preparo; perto das bordas, o trajeto é encurtado sem mudar a direção.
  Em voo, causa 100 de dano base (com os buffs do chefe), apenas uma vez por arremesso. Não causa dano depois do
  pouso. Ao cair sobre a canoa, desloca-a para fora do obstáculo; a colisão de voo respeita invulnerabilidade.

O chefe só para de perseguir durante o preparo do tronco. Continua andando durante a mãozona, os impactos e a recuperação. Cada impacto é mostrado por 0,35 segundo; intervalo de recuperação de 1,4 segundo e
aproximação de dois segundos antes de preparar o próximo ataque.

## Troncos persistentes

Cada tronco nasce com metade da vida máxima do chefe no instante do arremesso:
75.000 HP sem buffs. Não recebe buffs posteriores e não expira. Continua no
mapa mesmo após a morte do chefe, até ser destruído por lanças ou a partida
ser reiniciada. Não concede XP, cartas ou eliminações ao ser destruído.

O sprite horizontal tem tamanho de 160 × 56 pixels no jogo e gira conforme
a direção do arremesso. A hitbox é um retângulo simples de 160 × 36 pixels cobrindo o corpo do tronco, sem os galhos, com a
mesma rotação em voo e depois do pouso. Essa hitbox bloqueia a canoa, permitindo
deslizar pelas laterais. Movimento e knockback usam passos de no máximo oito
pixels para evitar atravessar o obstáculo. Lanças e peixes não têm sua passagem
bloqueada pela colisão da canoa; lanças podem acertar e destruir o tronco.
O minimapa mostra os troncos em marrom.

**F12** ou o botão correspondente invoca o chefe na sala de treino.
Artes: `assets/pai-do-mato-v2.png` e `assets/tronco-pai-do-mato-v3.png`.
Chefões são desenhados depois dos troncos e passam visualmente por cima deles.
As exclusões do exportador foram atualizadas; Tibanaré continua excluído.

Teste principal: `scripts/test_pai_do_mato.gd`. Use `-- --capture` com
renderização real para salvar a prévia em `.tools/pai-do-mato-preview.png`.

O sprite do Pai do Mato é espelhado apenas ao caminhar para a esquerda.
No normal e no treino, cada chefe mostra barra e HP atual/máximo sob o sprite.
No modo Boss Rush, a barra fica na parte inferior da tela, com vida atual e máxima. Troncos não exibem barra de vida.

## Áudio

Quatro efeitos originais em assets/audio: pai_log_throw_v1.wav (arremesso), pai_log_splash_v1.wav (pouso), pai_hand_slap_v2.wav (palma) e pai_roar_v1.wav (rugido OOOOOOHHH). O rugido é exclusivo do Pai do Mato e conserva a identidade em ondas mistas e na fila de anúncios. O controle Sons do Pai do Mato ajusta os quatro independentemente do Minhocão. O pouso toca uma vez e não inflige dano.

O pouso e a mãozona alteram visualmente a água no ponto do impacto: três ondas rápidas e respingos, sem preenchimento de cor na água. Dura um segundo, é emitido uma vez por pouso, acompanha a orientação do tronco e congela durante a pausa. Também expira no modo gráfico baixo. A palma V2 reforça o estalo agudo e o impacto de grave, com maior ganho no jogo.

As ondas do tronco avançam somente para a frente, na direção do arremesso, a 320 pixels/s. A palma cria círculos completos e redondos ao redor do impacto. Os respingos aumentaram para 48 no gráfico alto, 28 no médio e 12 no baixo, com trajetória balística e desaparecimento rápido. A mãozona emite o splash no impacto, sem depender de acertar o jogador.

O rastro da canoa tem círculos de maior contraste e espessura, além de um emissor separado com 6–10 partículas pequenas ao redor da canoa enquanto ela anda, sem ligação com a posição dos círculos. Só novas emissões dependem do movimento; os efeitos existentes desaparecem naturalmente e respeitam a pausa.

As partículas da canoa seguem a borda inferior real do sprite, detectada pela transparência, começando 16% depois da extremidade e terminando a 85% do comprimento. A linha e as partículas espelham junto com o barco; o afastamento da borda é de poucos pixels.

Os pixels nascem a meio pixel da borda do casco e têm velocidade de 18 pixels/s no sentido oposto ao movimento capturado na emissão, incluindo diagonais. Sua origem fica no mundo, sem acompanhar a posição atual do barco; a duração curta de 0,25 segundo mantém o efeito rente ao rastro.

O aviso do tronco mostra apenas uma faixa reta do início ao fim do percurso, com 36 pixels de largura (a espessura da hitbox), sem contorno ou marca separada de pouso.
