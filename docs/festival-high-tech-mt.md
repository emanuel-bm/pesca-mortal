# Festival High Tech MT

A edição usa o recurso de exportação `festival`. O preset **Windows Festival High Tech MT** gera `dist/pesca-mortal-festival-high-tech-mt.exe`. Para experimentar no editor, execute o projeto com `-- --festival`. A edição normal continua com o cadastro e ranking anteriores.

Ao abrir o executável Windows, o perfil **Festival Hightech** já está ativo automaticamente, sem cadastro, digitação de nome ou login. Ele é local e não publica resultados em seu nome. O painel desse perfil mostra partidas jogadas, tempo total e eliminações de todas as partidas, mesmo sem inscrição no ranking. Treino não entra nos totais. A contagem é de partidas, não de pessoas únicas, e os totais são por computador.

Ao morrer no infinito ou vencer no modo por chefões, o participante pode preencher **Seu nome ou apelido (opcional, salva no ranking)** e clicar em **Sair**. Com nome, uma tela de carregamento acompanha o envio e o jogo volta ao menu após confirmar a publicação. Sem nome, volta direto ao menu e mantém apenas os totais locais. Falhas de envio oferecem nova tentativa e preservam a fila local. A edição do festival não mostra Jogar novamente nem um botão separado para salvar. Nomes não precisam ser únicos e cada partida confirmada tem sua própria entrada; resultados menores também podem ser publicados. No infinito, vence o maior tempo; no modo por chefões, o menor tempo de vitória. Eliminações desempatam. A tela inicial mostra somente os dez melhores resultados do festival em cada modo; o serviço retorna até cem.

Os dados do festival ficam em `user://festival_high_tech_mt.json` e `user://festival_high_tech_mt_runs.json`, separados dos dados normais. Nomes confirmados e resultados aguardam sincronização se a conexão falhar. O campo de nome começa vazio a cada partida. Uma confirmação repetida não duplica o resultado.

## Atualizar a planilha existente

1. Na planilha de ID `1SUgm9oz8oyC9olnktHhaVdBlyymt8v-Bn8YV3Ikdvxk`, abra **Extensões → Apps Script** e substitua o conteúdo pelo `server/apps-script/Code.gs` desta branch.
2. Execute **setupFestival** uma vez. Ela cria a aba **Festival High Tech MT**, preservando `Players`, `Records`, `Seasons` e Lendas. Reexecutar não apaga resultados. Não execute a mudança de versão competitiva para ativar o festival.
3. Em **Implantar → Gerenciar implantações**, edite a implantação existente, selecione uma nova versão e implante mantendo a mesma URL de `online.cfg`.

O festival reúne todos os dias, sem filtro de data, e não é encerrado pela mudança de versão competitiva normal. Não é necessário conceder acesso à planilha ao agente se o responsável executar esses passos. A aba e o serviço só estarão prontos após essa publicação; alterar apenas o repositório não atualiza o Apps Script hospedado.

## Verificação

`node server/apps-script/test.cjs` valida os dois rankings e sua separação. Para o teste HTTP, deixe `node server/apps-script/test.cjs --serve` em um terminal e execute Godot headless com `--script res://scripts/test_festival.gd -- --festival`. O teste do festival usa arquivos temporários e o servidor local, sem publicar na planilha real. Builds de debug não publicam resultados reais: ao tentar salvar, uma mensagem explícita informa que nada foi enviado. Para validar a gravação na planilha, use o executável Windows exportado em release. O campo vazio não exibe cursor e não recebe foco automaticamente ao terminar a partida. O ranking do festival aceita cada partida confirmada, mesmo abaixo de um resultado anterior; ele não consulta o recorde pessoal global.
