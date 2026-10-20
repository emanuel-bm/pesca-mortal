# Progressão e ritmo até 20 minutos

Objetivo: reduzir a aceleração dos atributos para que a partida tenha mais espaço
antes do frenesi desejado aos 20 minutos. A mudança de fórmulas é uma primeira
calibração; os atributos agora crescem mais cedo e o ritmo precisa ser avaliado em partida.

## Implementado

Cada hit de um inimigo comum causa no máximo 90% da vida máxima atual do jogador,
arredondado para baixo para manter o dano inteiro dentro do limite. O teto acompanha
melhorias de vida máxima e não depende da vida restante: com 100 de vida máxima,
um hit pode tirar 90 e outro hit pode matar o jogador que ficou com 10.
Chefões e seus ataques, incluindo troncos arremessados, não recebem esse teto.

Cada escolha soma um incremento fixo. Dano inicial: 10; Impacto acrescenta 10:

| Melhoria | Acréscimo fixo por escolha | Após 10 escolhas |
| --- | --- | --- |
| Impacto | 10 de dano | 110 de dano |
| Vitalidade | 20 de vida máxima, 20% de 100 | 300 de vida máxima |
| Velocidade | 20 pixels/s, começando em 180 | 380 pixels/s |
| Ritmo | 0,5 ataque/s, começando em 1 ataque/s | 6 ataques/s |
| Aprendizado | 20 pontos percentuais de bônus | +200% de XP, total de 3× |

Os bônus temporários das cartas continuam aplicados sobre os atributos melhorados.
Vida base: piranha 10, pintado 100, pacu 40, dourado 100, Minhocão 20.000 e Pai do Mato
150.000. Peixes comuns receberam redução de 50%; chefes receberam redução maior.
Pai do Mato mantém 7,5 vezes a vida base do Minhocão e a mesma progressão temporal.
Rajada, Sorte, Persistência e Crítico já usam incrementos fixos; Crítico mantém o teto de 100%.
As prévias e a aplicação de melhorias usam a mesma fórmula.

Inimigos usam minutos completos: +20%, +20%, +10% e depois +6% por minuto,
sempre sobre a base inicial. Vida e velocidade não têm teto; dano dos peixes comuns
tem teto de 3× da base, atingido no minuto 28. Dano dos chefes segue a curva sem esse teto.
Os totais são aplicados apenas no nascimento. Inimigos vivos, incluindo chefões,
mantêm vida atual, vida máxima, velocidade, dano e multiplicadores de quando nasceram.
Chefes usam a mesma progressão temporal. Alcance e velocidade da arrancada do dourado
também usam essa curva; velocidade inicial da arrancada: 1.400 pixels/s.

| Atributo do inimigo | Antes, aos 13 min | Agora, aos 13 min | Agora, aos 20 min |
| --- | --- | --- | --- |
| Velocidade normal | 2,159×, já no teto desde 10 min | 2,10× | 2,52× |
| Vida máxima | 2,720× | 2,10× | 2,52× |
| Dano dos peixes | 1,665× | 2,10× | 2,52× |
| Dano dos chefes | 1,665× | 2,10× | 2,52× |

## Próximos ajustes a avaliar em partida

A quantidade de inimigos continua crescendo: a regra atual gera 19 peixes/s aos
13 minutos e 30 peixes/s aos 20. Se a tela continuar lotada cedo, experimentar
esticar essa curva por 20/13: `floor(max(2, minutos × 13/20) × 1,5)`.
Isso mantém o início em 3 peixes/s e leva aos 20 minutos a taxa de 19 peixes/s
que hoje aparece aos 13. Não foi aplicado nesta primeira calibração.

No normal, a sexta onda chega aos 13 minutos com um Pai do Mato; as seguintes
adicionam cada vez mais chefes, e os anteriores permanecem. Se o frenesi coincidir
com essa transição, avaliar deslocar a entrada do Pai do Mato para 20 minutos,
com ondas intermediárias menores, sem um salto de dificuldade logo na entrada.

Aprendizado já era aditivo. Seu efeito acelera novas escolhas, mas a exigência de
XP por nível também cresce. Avaliar tempo entre níveis e quantidade de melhorias
antes de reduzir o bônus: o dano e a frequência agora crescem mais devagar,
o que pode reduzir abates e XP. Alterar tudo simultaneamente pode enfraquecer
demais o jogador e aumentar o acúmulo de inimigos.

Comparar partidas com escolhas semelhantes nos minutos 5, 10, 13, 15 e 20:
nível, inimigos vivos, chefes vivos, abates por minuto e dano recebido. O critério
de sucesso é pressão controlável até perto dos 20 minutos, mantendo evolução
perceptível e escolhas úteis. Combinações de dano, frequência, projéteis e crítico
ainda podem acelerar o dano total, mesmo com cada atributo crescendo de forma aditiva.

Persistência soma 10 pontos percentuais por escolha. Crítico avança ao próximo
múltiplo de 10%, até 100%. Intangível dura 3 segundos antes da Persistência;
Fúria e Perfurante mantêm 6 segundos.
