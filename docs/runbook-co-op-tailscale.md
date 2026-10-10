# Runbook: testes co-op com Tailscale no Windows

Procedimento para permitir partidas por IP sem conceder acesso geral
ao computador do anfitrião ou aos demais dispositivos da rede Tailscale.
As regras abaixo limitam exposição; não substituem uma auditoria de
segurança do jogo, do Godot ou do sistema operacional.

## Pré-requisitos

- Ambos os jogadores usam os mesmos arquivos/commit do jogo.
- Tailscale instalado, conectado e com o anfitrião acessível ao convidado.
- Identidades confirmadas na página **Users**; contas GitHub podem usar
  identificadores como `usuario@github`, em vez de um endereço de e-mail.
- IP IPv4 Tailscale do computador anfitrião, obtido com `tailscale ip -4`.
- PowerShell como administrador para criar ou inspecionar regras de firewall.

Não registrar credenciais, tokens, e-mails reais ou IPs pessoais neste arquivo.

## Política de acesso no Tailscale

Na página **Access controls**, fazer uma cópia da política atual antes de
editar. O exemplo abaixo pressupõe apenas um proprietário e um convidado:
preserva acesso de saída do proprietário e SSH para seus próprios dispositivos;
outros usuários não recebem acesso por estas regras. Adaptar redes com mais
usuários ou serviços antes de substituir a política inteira.

Substituir `OWNER_ID`, `FRIEND_ID` e `HOST_TAILSCALE_IP` pelos valores corretos.

```json
{
  "grants": [
    {"src": ["OWNER_ID"], "dst": ["*"], "ip": ["*"]},
    {"src": ["FRIEND_ID"], "dst": ["HOST_TAILSCALE_IP"], "ip": ["udp:24567"]}
  ],
  "ssh": [
    {
      "action": "check",
      "src": ["OWNER_ID"],
      "dst": ["autogroup:self"],
      "users": ["autogroup:nonroot", "root"]
    }
  ]
}
```

Remover concessões gerais que também incluam o convidado, como
`{"src":["*"],"dst":["*"],"ip":["*"]}`. Permissões são cumulativas:
uma regra mais específica não anula uma autorização mais ampla.
Salvar e confirmar que Tailscale aceita a política antes de restaurar
o usuário. Verificar no recurso de prévia de acesso que o convidado pode
usar UDP 24567 no host, mas não TCP 22/445 ou UDP 24568, nem outros dispositivos.

Referências: [grants](https://tailscale.com/docs/features/access-control/grants),
[sintaxe](https://tailscale.com/docs/reference/syntax/policy-file).

## Firewall do anfitrião

Confirmar o nome da interface Tailscale no Windows. No ambiente validado,
o nome era `Tailscale`. Criar a regra uma única vez:

```powershell
New-NetFirewallRule -DisplayName "Pesca Mortal co-op Tailscale" -Direction Inbound -Action Allow -Protocol UDP -LocalPort 24567 -InterfaceAlias "Tailscale" -Profile Any
```

Verificar regra, porta e interface:

```powershell
$rule = Get-NetFirewallRule -DisplayName "Pesca Mortal co-op Tailscale"
$rule | Format-List Enabled,Direction,Action,Profile
$rule | Get-NetFirewallPortFilter | Format-List Protocol,LocalPort
$rule | Get-NetFirewallInterfaceFilter | Format-List InterfaceAlias
```

Resultado esperado: `Enabled=True`, `Inbound`, `Allow`, `UDP`, `24567`,
interface `Tailscale`. `Profile=Any` abrange perfis de rede do Windows;
a restrição de interface continua válida. Esta regra não concede acesso
pela interface Ethernet/Wi-Fi e não inicia um servidor por si só.
Outras regras existentes devem ser avaliadas separadamente.

## Antes e durante uma sessão

1. Confirmar a política restrita e restaurar o convidado em **Users**, se suspenso.
2. Abrir o jogo. Se Godot estiver no PATH: `godot --path . res://main.tscn`.
3. Anfitrião: **Co-op online → Criar sala**. Manter a tela de lobby aberta.
4. Convidado: **Entrar por IP**, usando o IP Tailscale do anfitrião sem porta.
5. Aguardar o lobby mostrar os jogadores, por exemplo **2 / 4**, antes de iniciar.
6. Iniciar modo infinito ou por chefões. Não há entrada após o início da partida.

Vida, XP, cartas e melhorias são compartilhados. O anfitrião controla
pausas e escolhas. Consulte [co-op](co-op.md) para comportamento e limitações.

## Diagnóstico de conexão

Com a sala aberta, verificar no host:

```powershell
Get-NetUDPEndpoint -LocalPort 24567 | Format-List LocalAddress,LocalPort,OwningProcess
```

Um listener confirma que o jogo abriu a porta; não comprova acesso remoto.
Abrir uma segunda janela e entrar por `127.0.0.1` testa o fluxo local do jogo.
Se falhar, recriar a sala e confirmar que a partida não começou.

No computador do convidado, executar `tailscale ping HOST_TAILSCALE_IP`.
Uma resposta confirma conectividade Tailscale, não autorização ao serviço UDP.
Após restringir a política, comportamento de ping pode variar conforme as
permissões; a entrada no lobby é a verificação final do jogo.
`Test-NetConnection -Port 24567` testa TCP e não valida este serviço UDP.

Se loopback funcionar e o acesso remoto falhar, conferir identidade,
suspensão, política, IP, conexões de entrada no Tailscale e firewall.
Registrar mensagem exata, commit em ambos os PCs e se o host estava no lobby.

## Encerrar testes

1. Voltar ao menu ou fechar o jogo para parar de hospedar.
2. Suspender o convidado em **Users** quando não for necessário acesso.
3. Opcionalmente desabilitar a regra local entre testes:

```powershell
Disable-NetFirewallRule -DisplayName "Pesca Mortal co-op Tailscale"
```

Reativar antes da próxima sessão com `Enable-NetFirewallRule` e o mesmo nome.
Suspensão mantém dispositivos cadastrados, mas bloqueia troca de tráfego
no tailnet; dispositivos podem ainda parecer conectados. Restaurar devolve
o acesso permitido pela política. Deletar o usuário remove seus dispositivos.
[Referência de suspensão](https://tailscale.com/docs/features/sharing/how-to/remove-team-members).

Mesmo com a regra restrita, um PC convidado comprometido pode enviar tráfego
malicioso à porta do jogo enquanto o usuário estiver ativo e o host ouvindo.
Não declarar o protótipo seguro apenas porque a política foi aceita.

## Registro de validação — 2026-10-10

- Verificado listener UDP 24567 no processo Godot.
- Verificada regra inbound Allow, habilitada, porta UDP 24567 e interface Tailscale.
- Verificado Tailscale conectado e preferência `ShieldsUp=False` no host.
- Probe ENet ao IP Tailscale do próprio host conectou; isso não valida caminho remoto.
- Entrada local falhou, depois funcionou ao recriar a sala e entrar antes do início.
- Usuário relatou partida remota funcionando, com movimento inicialmente aos saltos.
- Implementados interpolação, estados a 30 Hz, entradas a 60 Hz e buffers compactos.
- Testes headless de co-op, combate, cartas, Minhocão e navegação de menu passaram.
- Com 1.000 inimigos: 36.192 bytes de dados de inimigos por snapshot;
  aproximadamente 1,09 MB/s por cliente a 30 Hz, sem outros dados/overhead.
- Godot avisou sobre snapshots maiores que MTU: fragmentação/perda e desempenho
  remoto de grandes hordas continuam pendentes de teste.
- Usuário informou política restrita salva/ativa; a aplicação no painel não foi
  inspecionada diretamente pelo agente nem testada contra portas proibidas.

Para novos testes, acrescentar data, commits, jogadores, contagem de inimigos,
FPS local, tipo de conexão Tailscale (direta/relay), sintoma e resultado.
