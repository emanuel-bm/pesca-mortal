# Colisão e desvio de hordas — 08/10/2026

## Pesquisa

Não foi encontrada uma descrição oficial da Poncle que permita afirmar qual algoritmo exato de colisão entre inimigos o Vampire Survivors usa. Existem análises comunitárias de código descompilado; não foram usadas como prova da implementação oficial.

A documentação oficial do Godot recomenda evitar consultas de caminho desnecessárias a cada frame e distribuir atualizações entre grupos ou temporizadores. Para avoidance, neighbor_distance e max_neighbors controlam a quantidade de vizinhos considerados. A nossa arena aberta não precisa de uma busca global A* para contornar outros peixes: usamos busca local de direções com bloqueio contínuo de movimento.

Fontes primárias:
- https://docs.godotengine.org/en/stable/tutorials/navigation/navigation_optimizing_performance.html
- https://docs.godotengine.org/en/stable/tutorials/navigation/navigation_using_navigationagents.html
- https://github.com/henan-23/DOTS_Survivor — projeto similar de código aberto; seu autor documenta spatial hashing e ECS. Não é o código de Vampire Survivors, e os números anunciados pelo projeto não foram reproduzidos aqui.

## Diagnóstico local e implementação

A grade de 128 pixels dos projéteis estava sendo reutilizada para movimento. Em aglomerados, cada tentativa de direção repetia buscas por muitos vizinhos. O desvio tentava até oito alternativas por peixe e frame, inclusive quando não havia saída.

Mudanças:
- Grade exclusiva de movimento com células de 32 pixels; grade de projéteis preservada.
- Vizinhos consultados uma vez por decisão e armazenados em PackedVector3Array (posição e distância mínima), reutilizados nas alternativas.
- Filtro de distância antes do teste de segmento.
- Direção de contorno reutilizada por 120 ms, mantendo validação de colisão a cada deslocamento.
- Peixes completamente presos aguardam 80–112 ms antes de procurar novamente, distribuídos por índice; nunca avançam sem validar a colisão.
- Colisões mantêm área de 30%, bloqueio e teste do segmento para não atravessar outro peixe.

## Medição

Comando: Godot --headless --path . --script scripts/benchmark_crowd.gd

Posições iniciais fixas, mistura de piranhas/pintados após 420 segundos, 60 atualizações de perseguição a 1/60 s. A execução final fixa o seed de spawn em 417; o baseline inicial usou mistura aleatória, portanto as comparações são aproximadas. Somente movimento e reconstrução de grade; não inclui GPU, som, projéteis ou FPS do jogo completo. Baseline inicial e uma repetição final após otimização:

| Inimigos | Antes (ms/update) | Depois (ms/update) |
|---|---:|---:|
| 40 | 4,556 | 0,923 |
| 200 | 128,611 | 4,205 |
| 520 | 560,348 | 11,455 |

Resultados variam com hardware e distribuição. O caso de 520 ainda tem custo relevante; não é promessa de 60 FPS da cena completa.

Testes: bloqueio, retomada de movimento, contorno de inimigo parado, ausência de atravessamento no segmento, combate e modo infinito.


## Revisão: separação por forças

Após teste humano, o bloqueio rígido e as mudanças discretas de direção ainda produziam movimento percebido como saltos. Não foi reproduzido teletransporte de posição dos peixes em teste determinístico; a hipótese de parada/retomada e mudanças de direção é consistente com o código, mas não confirma sozinha o sintoma visual observado pelo usuário.

Pesquisa adicional:
- Craig Reynolds, Steering Behaviors for Autonomous Characters: https://www.red3d.com/cwr/steer/gdc99/ — referência primária de perseguição e separação por forças locais.
- https://www.reddit.com/r/godot/comments/158hsa8/ — relato de desenvolvedor que substituiu física por separation steering numa horda de 500 inimigos. Resultados de terceiros, não garantia para nossa cena.
- https://github.com/lukeod/vampiresurvivors-modding/blob/main/physics-system.md — análise comunitária de código descompilado, descreve ArcadePhysics customizada. Não é documentação oficial nem prova de que VS use nossa combinação de forças.

Alternativas avaliadas: bloqueio rígido preserva distância, mas cria filas e muitas tentativas; RVO/ORCA oferece desvio por velocidade com mais infraestrutura e custo; seek + separation combina perseguição e repulsão suave e aceita alguma sobreposição. Para a arena aberta e o comportamento solicitado, foi implementada a última opção.

Implementação atual para peixes: sem bloqueio rígido entre peixes, atração ao jogador mais repulsão local e componente lateral quando há bloqueio frontal. A repulsão usa a área proporcional de 30% mais uma margem de 6 px para começar antes de um empilhamento profundo. Velocidade total limitada à velocidade do peixe; aceleração máxima de cinco vezes essa velocidade por segundo. A posição muda apenas por velocidade * dt, sem correção instantânea de sobreposição. Forças são atualizadas a cada 60–76 ms, com no máximo 16 vizinhos locais; integração da velocidade ocorre todo frame. A colisão de dano e a movimentação especial do boss são preservadas.

Benchmark posterior: 40 peixes 0,445 ms, 200 peixes 3,313 ms, 520 peixes 9,714 ms por atualização. Mede apenas simulação de movimento, sem promessa de FPS da cena inteira. A distribuição final dos peixes varia conforme algoritmo, portanto comparação de desempenho é aproximada.

Testes adicionais: limite de velocidade e aceleração por frame, fluxo lateral ao redor de peixe parado, limite de deslocamento com 100 peixes coincidentes, combate e infinito.


## Arrays compartilhados e Teste de hordas

As consultas locais agora usam PackedVector2Array, PackedFloat32Array e PackedByteArray com posições, raios e estado dos inimigos. A captura é preparada junto à grade e reutilizada pela repulsão, evitando acessar Dictionary e recalcular raio de cada vizinho a cada consulta. Não foi necessário compartilhar um único vetor de perseguição: posições diferentes requerem vetores diferentes, e o gargalo medido foi a consulta de vizinhos.

Benchmark antes/depois nesta revisão: 40 inimigos 0,455 → 0,322 ms; 200 inimigos 3,370 → 1,794 ms; 520 inimigos 10,589 → 5,110 ms. Mede apenas a simulação de movimento, com o mesmo seed e posições iniciais; não é FPS total.

Menu: Teste de hordas. Começa com 259 piranhas, 259 pintados e 2 Minhocões. Jogador invencível, sem knockback, velocidade 2x a base, FPS sempre visível, contador total e por espécie. F5 acrescenta 100 peixes (limite 2000 entidades para o teste); F6 remove até 100 peixes, preservando chefões. Ataque automático e novos spawns ficam suspensos para manter carga controlada. Não salva histórico nem recordes. Recomeçar mantém o modo de teste; iniciar uma run normal restaura velocidade e dano recebido.

Teste: scripts/test_horde.gd valida contagem, controles, invencibilidade, velocidade, exclusão do histórico, reinício e restauração do modo normal.


## Otimização a partir do profiler da run

A captura do usuário mostrou draw_minimap em 2,03 ms e rebuild_enemy_grid em 1,37 ms com duas chamadas (tempos inclusivos; não somar funções pai e filha).

- Minimap agora é um Node2D separado em scripts/minimap.gd. Seus comandos de desenho são mantidos pelo CanvasItem entre atualizações; redesenhar o mundo não reconstrói o minimapa.
- Pontos e retângulo de câmera são preparados a 20 Hz. Transformação da arena é calculada uma vez por captura. Mudança de resolução e entrada em partida atualizam imediatamente.
- A simulação constrói somente crowd_grid antes de mover e somente enemy_grid de projéteis depois de mover. Cada estrutura é reconstruída uma vez. rebuild_enemy_grid permanece como helper completo para testes e ferramentas.

Benchmark scripts/benchmark_hud_grid.gd com 520 entidades: reconstrução das grades 1,571 → 0,714 ms por atualização. Antes, transformar os pontos individualmente custava 0,512 ms; depois, preparar toda a captura do minimapa custa 0,196 ms e ocorre no máximo 20 vezes por segundo. Estes números são headless e não incluem desenho GPU nem garantem FPS final.

Teste scripts/test_minimap.gd: marcadores por espécie, transformação, reutilização da captura, resize, visibilidade fora da run e posição atualizada na grade de projéteis. Também passaram testes de colisão, combate, hordas e consulta de projéteis contra busca exaustiva.


## Segunda captura do profiler e repulsão a 30 Hz

Frame selecionado: 20,90 ms (~47,8 FPS instantâneos). pursue_player teve 501 chamadas: 501 peixes simulados naquele frame; a captura não informa quantos sprites estavam visíveis. Tempos inclusivos: update_game 9,35 ms; pursue_player 4,53 ms; crowd_neighbors 2,59 ms/88 chamadas; rebuild_crowd_grid 2,13 ms. Não representam média da run e não devem ser somados com seus pais.

Alterações: snapshot/grade de repulsão atualizados a 30 Hz, com refresh imediato quando a quantidade muda. Grade de projéteis continua atualizada depois de cada movimento. Cálculo direto de repulsão sem criar PackedVector3Array intermediário; distância ao quadrado rejeita vizinhos distantes antes da raiz. Direção e velocidade desejada são armazenadas junto à força (60–76 ms), mas velocidade e posição continuam integradas em todos os frames, respeitando limites de aceleração. Grade antiga de colisão rígida permanece apenas para movimento do boss e testes auxiliares. Máximo de 16 vizinhos efetivamente dentro da região de influência.

O Teste de hordas agora informa PEIXES VISÍVEIS usando a mesma condição de visibilidade do desenho dos peixes.

Benchmark movimento + grades, seed 417: 520 peixes 4,770 → 3,491 ms. Inclui reconstrução de grade de projéteis nos dois casos; não inclui desenho e não garante aumento equivalente de FPS. Distribuição espacial resultante difere após modificar a repulsão.

Passaram testes de separação suave/limites de deslocamento, combate, hordas e infinito.


## Distribuição dos picos de repulsão

Duas capturas do usuário com 458 chamadas de pursue_player: frame 14,60 ms (~68,5 FPS) com 15 chamadas de crowd_separation; frame 20,66 ms (~48,4 FPS) com 167 chamadas. Repulsão passou de 0,18 para 4,29 ms, e update_game de 2,01 para 8,21 ms. Tempos inclusivos. A média de 100 FPS informada pelo jogador não contradiz esses frames individuais.

Causa observada: temporizadores independentes não garantiam distribuição dos cálculos. Implementado rodízio de janelas de no máximo 48 índices por frame; peixes aguardando mantêm velocidade desejada, com integração e limites de aceleração em todos os frames. Temporizador de força de 60–76 ms continua sendo respeitado quando possível. Em carga extrema, cada peixe leva mais tempo para renovar força, um compromisso explícito entre responsividade e estabilidade dos frames. Não limita movimento, dano ou projéteis.

Benchmark scripts/benchmark_crowd_spikes.gd: 458 peixes, seed 417, posições iniciais fixas, 180 atualizações de 10 ms, apenas snapshot de repulsão e perseguição. Antes: média 2,150 ms, p95 5,898 ms, máximo 9,365 ms. Depois: média 1,959 ms, p95 3,519 ms, máximo 7,488 ms. Valores aproximados de uma execução local; não inclui renderização nem garante FPS total. Trajetórias podem diferir com a nova distribuição temporal.

Teste scripts/test_crowd_budget.gd valida teto de 48, atendimento a todos os peixes em rodízio, remoção de entidades e reset da run. Também passaram combate, infinito e suavidade do movimento.


### Qualidade dos personagens e desenho em lotes

Ultra mantém o caminho de desenho e os sprites originais. Média/Baixa usam variantes recortadas e reduzidas uma única vez na inicialização, com filtro nearest: piranha 32/16 px, pintado 64/32 px, pescador na canoa 64/32 px, Minhocão 96/48 px (maior dimensão). O tamanho exibido no mundo não muda; colisões continuam usando as artes originais.

Os peixes em Média/Baixa usam dois MultiMesh, um por espécie, com transformações e cores individuais. Apenas peixes visíveis são enviados. A capacidade cresce quando necessário, sem realocar a cada morte. A ordem entre espécies passa a ser piranhas antes de pintados; chefões e seus avisos são desenhados depois, preservando a leitura. Movimento, simulação, vida e frequência de atualizações não mudam.

Validação: `test_character_quality.gd`, executado com renderização OpenGL real, verifica variantes, contagem visível, posições, espelhamento, brilho de dano e preservação da vida/raio. Captura Ultra/Média/Baixa em `.tools/quality-N.png`. `test_horde.gd` e `test_combat.gd` também passam.

Primeira medição local: cena estática com 520 inimigos, simulação pausada, VSync desativado, 10 frames de aquecimento e 90 medidos por preset: Ultra 3,035 ms/frame, Média 1,575, Baixa 1,465. Inclui diferenças de água e demais efeitos de cada preset; não isola o ganho de MultiMesh. Não representa FPS de uma partida real com IA, projéteis e colisões. Fonte da técnica: https://docs.godotengine.org/en/4.6/classes/class_multimeshinstance2d.html .

Segunda medição, com os dois chefões expostos e verificações de espelhamento/brilho: Ultra 3,162 ms, Média 2,452 ms, Baixa 2,165 ms por frame. Cenário diferente do primeiro; estes números incluem os chefões visíveis.


### Contato: filtros conservadores e personagem invencível

Os presets e as artes reduzidas foram mantidos por solicitação do jogador. Nos três perfis enviados, `enemy_overlaps` permanece relevante (2,05–4,85 ms), com cerca de 520 chamadas por frame. No teste de hordas, `receive_hit` rejeitava o dano só depois do teste detalhado de contato: agora esse modo pula a consulta de contato com o jogador. A repulsão, os projéteis e os ataques continuam sendo simulados.

Em `fish_visuals.gd`, a colisão mantém os mesmos polígonos, mas armazena os retângulos dos contornos por raio. Rejeita contornos e segmentos fora da região do ponto mais o padding antes das consultas geométricas. Margem conservadora de 0,0001 nos filtros evita descartar contatos na borda por arredondamento; a decisão final usa o padding original. Distâncias são comparadas ao quadrado.

`benchmark_contacts.gd`: 520 inimigos numa grade de 6 pixels perto do jogador, 120 iterações. Antes: consulta completa 6,553 ms, update_game de hordas 7,758 ms. Depois: 2,372 ms e 0,849 ms, respectivamente. Contagem de contatos idêntica (11880). A atualização usa dt=0, sem renderização; não extrapolar esses números para FPS de uma partida real.

`test_contact_equivalence.gd`: 29718 comparações com o algoritmo original, ambas as espécies, múltiplos raios, espelhamento, padding 0/5/14, pontos aleatórios e vértices/bordas. Passou. Também passaram `test_combat.gd`, `test_performance.gd` (grade versus busca completa de projéteis) e `test_horde.gd`.

Correção do teste de hordas: o jogador agora recebe contato, dano, som, recuo e cooldown pelo mesmo caminho das partidas normais. Somente a morte é impedida por prevent_player_death (HP mínimo 1), resetado ao iniciar cada run. Removido o bypass de contato e dano por modo. O ganho anterior de update_game em hordas incluía esse bypass e não representa mais o comportamento atual. Os filtros geométricos e seus ganhos isolados permanecem. test_horde valida contato pelo update_game, cooldown, recuo e dano letal sem morte.

Minimapa reativado com três MultiMesh (piranhas, pintados, chefões). Círculos de 32 segmentos compartilhados por espécie; transformações atualizadas na frequência anterior (Ultra 20 Hz, Média 10 Hz, Baixa 5 Hz). _draw envia até três lotes em vez de um draw_circle por inimigo. Jogador, bordas e viewport permanecem no desenho anterior. Capacidade reutilizada após remoções. Validado em OpenGL real, captura visual .tools/minimap-batched.png, testes de contagem/posição/raio e visibilidade. Transformações são verificadas no teste com renderer real porque o renderer dummy headless não as retorna.

Repulsão: maior raio por célula permite descartar células cuja caixa está fora do alcance de influência antes de percorrer seus moradores. Mesma ordem, limite de 16 vizinhos, força, snapshot e rodízio de 48. Metadados atualizados na reconstrução e em movimentos de chefão entre células; raio antigo pode ficar conservador até a próxima reconstrução. Contadores cumulativos crowd_candidates_checked e crowd_cells_skipped permitem medir consultas. Teste test_crowd_query.gd compara referência herdada (crowd_query_reference.gd) no mesmo objeto com cálculo novo em 3 distribuições determinísticas de 520 inimigos. Cenário denso: 797400 para 585220 candidatos (20 varreduras completas), 10,009 para 8,264 ms por varredura. Disperso: 4,254 para 4,027 ms; esparso: 2,215 para 1,922 ms. Estes tempos são 520 consultas por varredura, não um frame real com no máximo 48. Forças idênticas; ganhos variam pela distribuição. Benchmark móvel de 458 peixes teve variação de ambiente e não demonstrou ganho estável de p95; não prometer eliminação de picos.
