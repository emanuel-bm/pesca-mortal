# Sprites das cartas

Artes geradas com a ferramenta integrada ImageGen, usando os sprites existentes como referências. O sistema de drop e efeitos usa estes sprites em `scripts/cards.gd`.

| Arquivo | Símbolo |
| --- | --- |
| `perfurante.png` | Lança de madeira com ponta clara atravessando a piranha |
| `intangivel.png` | Escama rochosa do Minhocão |
| `furia.png` | Olho laranja do Minhocão com pupila vertical |
| `ima.png` | Ímã vermelho com uma ventrecha apoiada nos dois polos |

Os quatro sprites finais têm **64 × 96 pixels**, com transparência e margens alinhadas. São exibidos a 32 × 48 pixels no chão, com filtro nearest, flutuação e brilho animado de cima para baixo. `preview.png` apresenta os quatro ampliados em 4×, na ordem da tabela.

`source/` preserva as quatro imagens originais geradas. A preparação dos sprites apenas recorta as margens e reduz com nearest-neighbor, sem redesenhar os símbolos. `prompts.json` registra os prompts completos e as referências usados na ferramenta integrada.
