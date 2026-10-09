# Pesquisa: ataques, habilidades e cartas

Pesquisa feita em 08/10/2026. Nenhum sistema de cartas foi implementado.
O foco é o ciclo básico de cada jogo; versões, heróis, armas e equipamentos
podem acrescentar exceções. As descrições oficiais são gerais; exemplos de
armas e condições de ataque também usam referências comunitárias.

## Vampire Survivors

O jogador controla principalmente movimento, coleta e escolhas de construção
da run. Armas atacam automaticamente em seus próprios intervalos; não é
necessário apertar um botão a cada disparo. A mira varia: Magic Wand busca
inimigos próximos, Knife acompanha a direção para a qual o personagem olha,
e Garlic causa dano ao redor do personagem. Portanto, não é correto dizer que
todas as armas atiram no alvo mais próximo.

O XP permite escolher armas, melhorias e passivos. Essas aquisições normalmente
permanecem durante a run. Uma área de dano ou projétil pode desaparecer depois
de alguns segundos, mas a arma continua adquirida e pode produzi-lo novamente.
Baús participam da progressão e das evoluções de armas. Arcanas são cartas de
modificação das regras da build; não são, como regra, um ataque consumível que
só funciona por alguns segundos após pegar a carta.

Fontes: [descrição oficial na Steam](https://store.steampowered.com/app/1794680/Vampire_Survivors/),
[armas, referência comunitária](https://vampire-survivors.fandom.com/wiki/Weapons),
[Arcanas, referência comunitária](https://vampire-survivors.fandom.com/wiki/Arcanas).

## Megabonk

O ciclo combina movimentação/exploração em 3D, coleta de XP e loot e escolhas
de melhorias aleatórias, inclusive com raridades diferentes. Os ataques são
majoritariamente automáticos; armas têm padrões e regras de mira próprios.
Algumas buscam alvos próximos, enquanto há armas direcionáveis como Sniper
Rifle. Logo, também não se deve tratar toda arma como auto-mira no mais próximo.

Armas, tomos e itens formam a build. Tomos alteram atributos, como frequência de
ataque, quantidade e área. Há efeitos automáticos que se repetem por intervalo,
efeitos passivos e efeitos condicionais. O fato de um efeito durar pouco não
significa que o item que o concedeu desapareça. O ciclo básico não exige
consumir uma carta para cada ataque.

Fontes: [descrição oficial](https://store.steampowered.com/app/3405340/Megabonk/),
[armas](https://megabonk.wiki/wiki/Weapons), [tomos](https://megabonk.wiki/wiki/Tomes),
[arma direcionável](https://megabonk.wiki/wiki/Sniper_Rifle).

## Archero (jogo original mobile)

No combate básico, o jogador movimenta o herói para desviar e precisa parar
para que o ataque básico automático aconteça. Não há mira manual por disparo;
o posicionamento influencia o alvo, normalmente o inimigo próximo. Esse
alternar entre deslocamento e ataque diferencia Archero dos dois survivors.

O jogador recebe escolhas de habilidades ao subir de nível. Exemplos incluem
flechas extras, perfuração e ricochete; outras habilidades são passivas ou
condicionais, como cura por abate. A escolha normalmente permanece na run,
em vez de ser consumida uma única vez. Equipamentos e heróis podem adicionar
outros comportamentos, portanto essa descrição não afirma que todo recurso
de todas as versões seja exclusivamente passivo.

Fontes: [Habby](https://www.habby.com/game/detail/archero),
[guia da Apple sobre habilidades](https://apps.apple.com/ca/story/id1500619510),
[explicação comunitária do ataque parado e seleção de alvo](https://www.reddit.com/r/Archero/comments/c4s5g1/),
[Multishot](https://archero.fandom.com/wiki/Multishot).

## Distinções úteis para decidir o sistema de Pesca Mortal

- **Aquisição:** carta dropada, escolha ao subir de nível ou baú.
- **Permanência:** consumível, temporária ou válida até o fim da run.
- **Ativação:** por botão, automaticamente por intervalo, continuamente ou por
  condição como acerto, abate ou dano recebido.
- **Duração do efeito:** tempo de vida do projétil, aura ou benefício produzido.

Essas dimensões são independentes. Exemplo hipotético: uma carta adquirida
permanentemente na run poderia liberar uma onda de água automática a cada
oito segundos; cada onda duraria um segundo. Uma carta consumível de cura,
em contraste, poderia agir uma única vez. São alternativas de design para
discutir depois, não funcionalidades já implementadas.
