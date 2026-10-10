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

O host valida entradas e simula combate. Clientes enviam direções a 20 Hz;
o host envia estados completos a 10 Hz em canais ENet separados.
Esta primeira versão não tem previsão de movimento e transmite todos
os inimigos; latência e grandes hordas precisam de avaliação em partidas
reais antes de distribuição. Áudio de eventos locais de combate não é
replicado aos clientes nesta versão.

Validação automatizada: `godot --headless --path . --script res://scripts/test_co_op.gd`.
O teste conecta quatro instâncias por loopback e verifica início,
movimento, estado compartilhado, pausa e desconexão.
