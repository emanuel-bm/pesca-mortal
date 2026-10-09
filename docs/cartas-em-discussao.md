# Cartas — proposta em discussão

Pesquisa e discussão iniciadas em 09/10/2026. O usuário confirmou as regras abaixo e autorizou a implementação, concluída nesta data.

## Termo definido

O usuário definiu **carta** como o nome dos power-ups do jogo. Ver `../GLOSSARY.md`.

## Referências

- Megabonk combina loot, XP e escolhas aleatórias para construir a run ([Steam oficial](https://store.steampowered.com/app/3405340/Megabonk/)). Power-ups temporários são uma categoria distinta dos itens da build; a documentação comunitária lista condições como Rage, Shield e Frost ([wiki comunitária](https://megabonk.wiki/wiki/Conditions), [guia comunitário de power-ups](https://megabonk.org/guides/mechanics/powerups/)). As fontes consultadas não sustentam copiar percentuais de drop exatos.
- Vampire Survivors tem pickups de coleta, controle e ataque: Vacuum, Orologion, Rosary e Nduja Fritta Tanto. São distintos das Arcanas que modificam a build ([pickups, wiki comunitária](https://vampire-survivors.fandom.com/wiki/Pickups), [Rosary](https://vampire-survivors.fandom.com/wiki/Rosary)).
- Archero inspira combinações de habilidades: Ricochet + Multishot e Piercing Shot + Bouncy Wall. São escolhas de habilidade para a run, não equivalentes diretos a consumíveis de oito segundos ([guia da Apple](https://apps.apple.com/ca/iphone/story/id1470165753)).

## Proposta do usuário e referência visual

- Chances sugeridas: piranha 1%, pintado 5%, chefe 100%.
- Imagem fornecida: Ímã recolhe todo XP do mapa; Fúria por 10 s com +50% dano, +50% frequência de ataque, +20% velocidade; Intangível por 6 s; Perfurante por 8 s.
- Os números da imagem são referências de discussão, não decisões aprovadas.

## Recomendações para avaliar

- Primeiro conjunto: Ímã, Fúria, Intangível e Perfurante.
- Expansões possíveis: Cura (20% da vida máxima), Redemoinho (afastamento local), Correnteza (lentidão temporária dos peixes), Ricochete (até dois saltos por lança).
- Fúria: +50% dano e +50% frequência produzem aproximadamente 2,25 vezes o dano por segundo antes de outros limites. O usuário confirmou também +20% de velocidade.
- Separar atributos da build de efeitos temporários; congelar duração durante pausas; mostrar ícone e tempo restante; impedir múltiplos acertos da mesma lança no mesmo peixe.

## Fatos do projeto relevantes

- Antes desta implementação, havia apenas melhorias de nível e cristais de XP, sem cartas.
- Depois de 30 s, a chance de spawn de pintado é 25%. Se os abates seguirem essa proporção, 1%/5% representam 2% em média, aproximadamente uma carta a cada 50 abates. A proporção real de abates pode diferir.
- Com essa mistura hipotética: 100 abates/min → 2 cartas/min; 300 → 6; 600 → 12. Valores esperados, não garantias.
- No modo por chefões, a morte do chefe encerra a partida: uma carta temporária posterior não teria uso no combate atual.

## Decisões confirmadas — primeira rodada

- Cartas são consumíveis com efeito imediato ou temporário. Melhorias de nível continuam compondo a build.
- Coleta ativa automaticamente a carta, sem inventário ou botão de uso.
- O objetivo são benefícios ocasionais; a meta inicial discutida é 2–4 coletas por minuto, sujeita a teste.
- Chefões garantem uma carta no infinito; no modo por chefões, o abate final encerra a partida.
- O usuário pediu reduzir as chances dos peixes a um quarto: **piranha 0,25%**, **pintado 1,25%**. Mantida a garantia de chefe conforme a decisão anterior.
- Com 75% de abates de piranha e 25% de pintado, a chance média passa a **0,5%**, uma carta a cada 200 abates em expectativa. A 100/300/600 abates por minuto, são 0,5/1,5/3 cartas por minuto, sem contar chefes. A meta de frequência não é uma garantia de drop.

## Decisões confirmadas — segunda rodada

- Conjunto inicial: Ímã, Fúria, Intangível e Perfurante.
- Cada carta tem 25% de chance quando um drop ocorre, inclusive em chefes. Esse sorteio é separado da chance de ocorrer um drop.
- **Duração dos efeitos temporários: 6 s**. Substitui os 10 s originais da Fúria e os 8 s da Perfurante. **Ímã é instantâneo**, conforme a correção posterior do usuário.
- Ímã inicia a atração de todo XP existente no mapa, sem conceder experiência imediatamente. Cada XP marcado segue a canoa até ser coletado, independentemente do raio normal, a 630 pixels/s (redução de 25% sobre 840). Novos XP não herdam a atração global. Todo nível ganho na chegada deve oferecer sua própria tela de melhoria, sequencialmente, preservando o XP excedente.
- **Fúria:** +50% dano, +50% frequência de ataque e +20% velocidade.
- **Intangível:** não recebe dano durante o efeito.
- **Perfurante:** novas lanças atravessam os peixes enquanto houver saldo de dano, com um acerto por alvo por lança. Desaparecem ao esgotar o saldo ou atingir a borda.
- Efeitos diferentes coexistem; repetir o mesmo efeito renova a duração integral, sem somar potência nem acumular tempo.
- Coleta apenas por contato com a canoa, sem atração de XP. A carta no chão desaparece após 30 s de jogo ativo, com aviso nos últimos 5 s. Esse prazo é distinto da duração de 6 s do efeito.
- Fúria e Perfurante respeitam as fases vulneráveis dos chefes; Intangível protege contra contato, emergência e investida.

## Velocidades — mudança solicitada e aplicada

- Removido o teto de velocidade do jogador, inclusive na prévia e na disponibilidade de melhorias.
- Removido o teto de velocidade dos peixes baseado no jogador, no spawn, nos buffs e no movimento.
- Removido também o teto de multiplicador de movimento dos chefes: a progressão aplica o multiplicador completo. Tempos dos avisos permanecem iguais.
- O bônus temporário de velocidade da Fúria deve afetar apenas o jogador.
- Corrigido o fluxo de melhorias para abrir imediatamente a próxima escolha quando houver XP suficiente para outro nível, sem retomar o combate entre as telas.
- Estas alterações de velocidade e XP foram aplicadas antes da implementação das cartas.

## Artes das cartas

Quatro sprites em pixel art inspirados em cartas de baralho foram criados em `assets/cards/`, com 64 × 96 pixels e transparência. Perfurante mostra a lança atravessando a piranha; Intangível, uma escama do Minhocão; Fúria, seu olho; Ímã, um ímã com uma ventrecha apoiada nos dois polos. O usuário confirmou que “folha” se referia à Fúria. Originais e prompts foram preservados.

## Implementação e animação

- Cartas no chão: 32 × 48 pixels, oscilação vertical de quatro pixels, ciclo de 1,8 s; faixa de brilho que percorre de cima para baixo e se repete a cada 2,4 s.
- Aos 25 s de existência, alternam visibilidade a cada 0,5 s; aos 30 s desaparecem. Coleta continua possível durante a piscada.
- Cronômetros, flutuação e brilho usam apenas tempo ativo da partida. Reiniciar limpa drops e efeitos.
- Ícones com nomes e tempo restante aparecem na parte inferior da tela; não há inventário ou ativação manual.
- Fúria aplica bônus sobre a build sem modificá-la. Lanças comuns usam o estado da Fúria no instante do acerto; lanças perfurantes fixam seu saldo inicial no disparo, incluindo Fúria se estiver ativa, sem recalcular ou repor esse saldo em voo.
- Perfurante marca apenas novas lanças, que conservam a perfuração mesmo após o efeito terminar. Colisão amostra o trajeto em intervalos de até oito pixels e registra os inimigos já atingidos. Cada alvo consome o menor valor entre sua vida atual e o saldo de dano da lança. Exemplo confirmado: 50 de dano contra peixe com 30 de vida mata o peixe e deixa 20 de saldo; outro peixe com 30 recebe 20, fica com 10, e a lança desaparece. O dano exibido é o valor efetivamente consumido.
- Intangível respeita a invulnerabilidade pós-dano já existente; uma não apaga a outra.
- Na sala de treino, F9 invoca as quatro cartas próximas à canoa.
- `scripts/test_cards.gd` verifica drops, contato, bônus, XP de múltiplos níveis, frações de XP, perfuração, vulnerabilidade do chefe, piscadas, pausas, reinício e F9. Testes de combate, prévia, velocidade, treino, infinito, Minhocão e grade de colisões também passaram. A renderização foi conferida no Godot com OpenGL.

## Verificação das mudanças de velocidade e XP

- Importação headless concluída.
- Passaram: testes de velocidade/progressão sequencial de XP, prévia de melhorias, Minhocão, limites das outras melhorias e melhorias de vida/XP.
- O teste de combate foi atualizado para a base definitiva de 50 de vida, incluindo 40 após dano de contato e 40 de cura ao subir de nível partindo de 10. Testes de combate e melhorias de vida/XP passaram.
