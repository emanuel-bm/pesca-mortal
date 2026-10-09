# Sprites

Gerados com a ferramenta integrada ImageGen, com transparência, usando as quatro
fotografias fornecidas pelo usuário como referências de personagem.
Os arquivos finais são `minhocao.png` e `player.png`.

## Prompt: Minhocão

Use case: stylized-concept. Create one transparent game sprite asset: a single Minhocão boss for a top-down 2D pixel art survivors game. References are the four attached photographs of the Cuiabá serpent statue: use gray olive rocky armored scales, thick serpentine neck, orange slit eye, red open mouth and two long ivory fangs. Isolated full creature, compact curled body below upright large head, facing diagonally down-right, high 3/4 game perspective. Crisp chunky pixel art, limited palette, dark outline, no antialias painterly strokes, no scenery, no water, no pedestal, no people, no letters. Centered square canvas with generous transparent margins. Readable at 100 pixels on screen. Use attached photos as subject references only.

## Prompt: personagem

Use case: stylized-concept. Asset: single transparent pixel art game character sprite. Subject: a Cuiabá river fisherman and spear fighter inspired by the human boatman in the attached Minhocão statue photographs: adult brown-skinned man wearing a broad straw hat, sleeveless muted sand shirt, dark teal trousers, brown boots, holding a wooden spear with a small ivory-metal tip. Full body isolated, facing diagonally down-right in high three-quarter perspective for a top-down survivors game. Crisp chunky 32-bit-era pixel art, limited earthy palette, strong dark outline, readable tiny at 48 pixels tall. Square canvas, character centered with transparent margins. No canoe, no serpent, no background, no ground shadow, no text or other characters. This is a standalone sprite matching a rocky olive serpent boss.

## Água animada e novos sprites

`piranha.png`, `pintado-v2.png`, `player-canoe.png` e `water.png` foram gerados
com ImageGen integrado. O personagem anterior foi usado como referência na
edição da canoa. Os peixes mantêm 26/44 pixels de dimensão máxima; a colisão
acompanha a silhueta opaca e seu espelhamento.

Prompts de produção:

- Piranha: single transparent pixel art piranha sprite for a top-down survivors game, facing right, compact silver body, red belly, sharp teeth, dark outline, chunky pixels, readable at 26 pixels, no scenery or text.
- Pintado: single transparent pixel art Brazilian pintado catfish sprite, facing right, elongated silver gray body with dark spots and whiskers, high three-quarter perspective, dark outline, chunky pixels, readable at 44 pixels, no scenery or text. Clean variant removes stray pixels outside the fish silhouette.
- Canoa (edição de player.png): preserve the existing fisherman, straw hat, pose, clothing and spear; place him standing in a small wooden canoe, diagonal high three-quarter top-down perspective, matching pixel art, isolated on transparent background, no water or scenery.
- Água: seamless tileable top-down pixel art river water texture, dark muted teal palette, subtle ripples and small highlights, low contrast so game enemies remain readable, no shore, objects or text, opaque square texture.

`water.gdshader` anima duas camadas de reflexos celulares deformados, com
ondas suaves e amostragem em pixels de mundo. Mantém a paleta verde-azulada
escura; o vídeo fornecido pelo usuário serviu como referência de movimento.
A canoa deixa ondulações temporárias. A animação congela durante a pausa.

## Ventrescha de XP

Arquivo: `ventrescha.png`. Gerado com ImageGen integrado, fundo transparente.
Prompt: Create a single transparent pixel art game pickup sprite: a small cooked Brazilian fish ventrescha, one belly cut of fish, golden grilled crispy skin with a few dark grill marks and pale cream flaky flesh visible on cut edge. A compact appetizing single portion, no plate, no garnish, no utensils. High three-quarter top-down perspective, chunky crisp pixel art, limited warm earthy palette, dark outline, strongly readable at 16 pixels across. Centered isolated object with transparent margins. No text, no scenery, no shadows outside object. Match a retro 2D river fishing survivors game.

## Ventrescha revisada

`ventrescha-v2.png`: gerada com ImageGen integrado, com as fotos de ventrecha
frita fornecidas pelo usuário como referência.
Prompt: Generate one isolated pixel art XP pickup for a 2D top-down river game, based on the attached food photos: a single narrow elongated strip of fried fish belly ventrescha, irregular golden-brown crispy batter, slightly curled wavy edges, a long shallow groove along the center, warm ochre and brown palette. NOT a thick rectangular salmon steak, NOT grilled with black grill lines. High three-quarter top-down perspective, chunky crisp pixel art, strong dark brown outline, readable at 14 to 20 pixels. One strip only, centered with transparent margin, no plate, no vegetables, no garnish, no text. Use the provided photo as reference for the shape and fried golden crust.

## Ventrescha sem abertura central

Arquivo `ventrescha-v3.png`, editado com ImageGen integrado usando v2 como referência.
Prompt: Edit this pixel art fried fish ventrescha pickup. Preserve the elongated irregular strip silhouette, orientation, golden-brown crispy batter palette, chunky pixel art and isolated transparent background. Remove the long central split, trench and exposed pale interior entirely: fill that groove with continuous unbroken golden crispy fried batter. It must look like a single solid fried fish belly strip, with a gently rounded solid top surface, no slit, no hole, no cut-open center. Keep minor irregular fried texture and natural shallow highlights only. No surrounding glow or shadow, no plate, no text.
