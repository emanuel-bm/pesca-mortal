# Co-op online por IP

No menu, selecione **Co-op online**. O anfitrião escolhe **Criar sala**;
até três amigos escolhem **Entrar por IP** usando o IP Tailscale do anfitrião.
Todos devem usar a mesma versão do jogo e conseguir acessar o computador
do anfitrião pela rede Tailscale. A porta do jogo é **24567/UDP**; permita
o executável no firewall do anfitrião. Pela rede Tailscale não é necessário
encaminhamento no roteador.

O anfitrião inicia o modo infinito ou por chefões após todos entrarem.
Não há entrada durante a partida. Cada jogador move sua própria canoa
com WASD/setas e ataca automaticamente. Vida, invulnerabilidade, XP,
melhorias e cartas são compartilhados pela equipe. O anfitrião escolhe
melhorias e controla pausas. A morte encerra a partida para todos.
Resultados cooperativos não entram no histórico ou ranking individual.

Clientes podem sair pelo botão Desconectar quando o anfitrião pausa.
Se o anfitrião sair, a sessão termina. Não há migração de anfitrião,
reconexão em partida ou descoberta automática de salas.

O host valida entradas e simula combate. Clientes enviam direções a 60 Hz;
o host envia estados a 30 Hz em canais ENet separados. A frequência depende
do FPS local; quadros lentos não geram rajadas de pacotes para compensar.
O temporizador preserva sobras entre quadros para manter as taxas desejadas.
Inimigos usam buffers numéricos compactos com apenas campos de renderização, sem
chaves de dicionário, dados de colisão ou caches de IA do anfitrião.
Clientes interpolam canoas, inimigos, projéteis e XP entre estados durante
cada quadro de renderização, com aproximadamente 33 ms de atraso visual.
Entidades usam IDs estáveis para evitar saltos quando outras são removidas;
novos objetos e teletransportes aparecem diretamente na posição recebida.
Pausas congelam a interpolação, e pacotes atrasados não fazem extrapolar
o movimento além do último estado recebido. Cartas reutilizam sprites.
Esta primeira versão não tem previsão de movimento e transmite todos
os inimigos; latência e grandes hordas precisam de avaliação em partidas
reais antes de distribuição. Áudio de eventos locais de combate não é
replicado aos clientes nesta versão.

Validação automatizada: `godot --headless --path . --script res://scripts/test_co_op.gd`.
O teste conecta quatro instâncias por loopback e verifica início,
movimento, estado compartilhado, pausa e desconexão.
Também verifica interpolação entre atualizações, identidade de entidades,
teletransportes, pacotes atrasados e reutilização de sprites de cartas.
Verifica também taxas de envio a 100 FPS e mede serialização e tamanho
de snapshots com 1.000 inimigos, incluindo os avisos do Minhocão.
