# Guia para concluir a migração dos rankings

## O que já foi preparado

A pasta `server/mongodb` contém a API para os rankings Global e Festival, autenticação compatível com as contas existentes, importação com validação e conferência de conflitos, backup/restauração, fechamento de temporada sem apagar recordes, Dockerfile e testes com MongoDB local real. Os auxiliares de exportação e ponte do Apps Script estão prontos como arquivos separados.

Em 27/10/2026, a exportação atualizada da planilha foi importada e conferida no banco de produção `pesca_mortal`. A API está publicada em `https://pesca-mortal-api.fly.dev/exec`, na região São Paulo (`gru`), com uma máquina de 512 MB sem suspensão automática. As gravações estão habilitadas e a versão 0.5.2 do jogo aponta diretamente para essa API.

A exportação original e o backup MongoDB ficam fora do Git. Os passos abaixo documentam o procedimento de migração e recuperação; não devem ser repetidos automaticamente em produção. A ponte Apps Script ainda não foi instalada: executáveis antigos mantêm sua URL anterior e precisam ser atualizados para usar o novo serviço.

## 1. Criar o banco na sua conta MongoDB Atlas

1. Entre no Atlas e crie um projeto e um cluster **Free** persistente na sua conta. Não usar cluster temporário/ephemeral.
2. Crie um usuário de banco com senha forte e permissão de leitura/gravação somente no banco `pesca_mortal`. Para homologação, use outro banco e a permissão correspondente. O usuário de banco é diferente do login da sua conta Atlas.
3. Em **Connect → Drivers**, obtenha a URI `mongodb+srv://...`. Guarde-a como segredo do servidor; nunca coloque em `online.cfg` ou em uma build.
4. Em **Network Access**, permita seu IP temporariamente para inicialização/importação local. Quando escolher a hospedagem, permita também os intervalos de saída dela. Remova o acesso local se não precisar mais dele. Não é necessário liberar todos os IPs.

[Conectar ao Atlas](https://www.mongodb.com/docs/atlas/connect-to-database-deployment/) · [Lista de IPs](https://www.mongodb.com/docs/atlas/security/add-ip-address-to-list/)

O banco Free tem limites próprios, inclusive aproximadamente 0,5 GB com índices e 100 operações por segundo. Isso é suficiente como ponto inicial para o volume informado, sem equivaler a capacidade ilimitada. [Limites atuais](https://www.mongodb.com/docs/atlas/reference/free-shared-limitations/)

## 2. Exportar e preservar os dados do Google

1. Faça uma cópia de segurança do arquivo original e preserve as versões históricas necessárias. Se cada versão tiver abas diferentes com dados, não faça várias restaurações sobre o mesmo original para tentar juntá-las.
2. Abra o Apps Script associado ao serviço que o jogo usa. Em Configurações do projeto, confira `SPREADSHEET_ID` e `ACTIVE_VERSION`. O ID precisa corresponder ao arquivo que contém os dados. Não execute `setupRanking`, `setupFestival` ou mudança de temporada como tentativa de recuperação.
3. **Adicione um arquivo separado** chamado `Export.gs` e copie nele `server/mongodb/legacy/Export.gs`. Não substitua o `Code.gs` atual.
4. Execute manualmente `exportRankingBackup`. O Google poderá pedir permissão adicional de Drive para criar o backup; isso não é publicar uma nova versão do web app.
5. Abra o link privado informado no registro de execução e baixe o JSON. Ele contém todas as linhas das abas reconhecidas, não apenas o top 100. Contém hashes de contas: não publique o arquivo nem o inclua no Git.
6. Guarde o arquivo como `server/mongodb/exports/backup.json` e mantenha outra cópia fora do projeto. Essa pasta é ignorada pelo Git.

O importador exige Players, Records, Seasons e Festival High Tech MT com cabeçalhos válidos, mais cada arquivo de Lendas listado em Seasons. Se alguma aba estiver ausente ou vazia sem cabeçalho, ele interrompe. Isso é um sinal para recuperar/conferir a origem, não para criar dados fictícios. A consulta pública com 24 resultados não é um backup completo.

Se o backup parecer vazio, execute `diagnosticarFonteRanking` no mesmo arquivo auxiliar. O registro mostra o link da fonte configurada, a versão ativa, os nomes das abas e quantas linhas existem além do cabeçalho, sem revelar dados das células. O exportador recusa criar um arquivo se não encontrar abas reconhecidas com dados. Não altere o ID por tentativa: compare primeiro o link registrado com o arquivo esperado.

Se houver dados repartidos entre versões históricas, consolide primeiro uma exportação completa e confira conflitos. O importador não escolhe sozinho qual versão conflitante está correta.

Compatibilidade de contas antigas: nomes históricos são preservados mesmo se não seguirem a regra atual de novos cadastros. Se `nickname_key` divergir do nome em minúsculas, o importador reconstrói essa chave derivada, conserva a antiga em `legacy_nickname_key` e registra a adaptação no relatório. Colisões entre nomes continuam bloqueando a importação. IDs, hashes, nomes exibidos e nomes congelados de Lendas não são alterados.

## 3. Preparar o ambiente local e validar sem importar

Instale Node.js 22 ou superior com npm, se sua instalação não oferecer esses comandos. Em PowerShell, na raiz do repositório:

```powershell
Set-Location server/mongodb
npm ci
Copy-Item .env.example .env
New-Item -ItemType Directory -Force exports | Out-Null
```

Edite `.env` localmente:

```dotenv
MONGODB_URI=mongodb+srv://USUARIO:SENHA@SEU_CLUSTER.mongodb.net/?retryWrites=true&w=majority
MONGODB_DATABASE=pesca_mortal_homologacao
HOST=127.0.0.1
PORT=8080
```

Use a URI produzida pelo Atlas com a senha corretamente codificada; o exemplo é ilustrativo. Não compartilhe esse arquivo. Escolha primeiro um banco de homologação autorizado ao usuário criado.

```powershell
npm run import -- exports/backup.json
```

Esse comando apenas valida o arquivo. Ele não acessa o MongoDB nem altera a planilha. Examine as contagens do relatório em `reports`. Erros interrompem a importação e não devem ser resolvidos apagando linhas sem conferir a origem.

## 4. Ensaiar a importação em homologação

Confira `active_version` no JSON e use a mesma versão em `init`. Abaixo, `0.5` é um exemplo adequado somente se a exportação confirmar essa versão:

```powershell
npm run admin -- init 0.5
npm run import -- exports/backup.json --check-db
npm run import -- exports/backup.json --apply
npm run admin -- status
npm run backup
```

`init` cria índices e deixa envios bloqueados. O importador recusa versão ativa diferente e não sobrescreve documento existente de conteúdo diferente. Aplicar o mesmo arquivo novamente deve informar registros inalterados, sem duplicação. Uma falha durante a transação aborta a importação inteira.

Antes de aceitar tráfego, compare contagens, melhores resultados e Lendas com a origem. Confira também se os resultados em Records pertencem à versão esperada: resultados de outra versão não aparecem no ranking atual.

Para ensaiar a restauração, mude `.env` para um **terceiro banco vazio**, inicialize na versão do backup e importe o JSON de `backups` com os mesmos comandos. Volte depois ao banco de homologação. A restauração é uma importação validada; não precisa apagar um banco existente para testar.

Para testar a API em homologação:

```powershell
npm run admin -- enable
npm start
```

Em outro terminal, `http://127.0.0.1:8080/ready` deve retornar `{"ok":true}`. Um pedido POST de ranking pode ser conferido assim:

```powershell
$rankingBody = '{"action":"ranking","event_id":"festival-high-tech-mt","competitive_version":"0.5"}'
Invoke-RestMethod -Uri http://127.0.0.1:8080/exec -Method Post -ContentType application/json -Body $rankingBody
```

`npm test` roda a suíte local descartável; não usa seu banco Atlas. A primeira execução baixa o MongoDB usado nos testes.

## 5. Hospedar a API HTTPS

O Atlas fornece o banco; a API Node precisa de hospedagem separada. O Dockerfile em `server/mongodb` permite usar um provedor de containers. Uma rota possível é Render, com um Web Service Docker vinculado ao repositório:

1. Envie os arquivos da implementação para seu repositório, sem `.env`, backups, exports ou relatórios privados. Se a publicação usar outra branch, inclua nela a pasta `server/mongodb` completa; ela não depende dos arquivos Godot em execução.
2. Crie um Web Service com contexto Docker `server/mongodb` e Dockerfile `server/mongodb/Dockerfile` quando os campos forem relativos à raiz do repositório. Se definir `server/mongodb` como Root Directory, os caminhos passam a ser relativos a essa pasta: contexto `.` e Dockerfile `Dockerfile`.
3. Configure as variáveis secretas `MONGODB_URI` e `MONGODB_DATABASE=pesca_mortal`. Use `HOST=0.0.0.0`; o servidor respeita `PORT` fornecido pela hospedagem.
4. Obtenha os intervalos de IP de saída do serviço e adicione-os à lista do Atlas. No Render ficam em **Connect → Outbound**. [Documentação](https://render.com/docs/outbound-ip-addresses)
5. Inicialize esse banco de produção pela CLI local, ajustando `.env` para ele, e mantenha os envios desativados. A aplicação não inicializa dados automaticamente.
6. Confira `https://SEU_SERVICO/ready`. Anote a URL `https://SEU_SERVICO/exec` para o corte.

No Render Free, a API dorme após 15 minutos sem tráfego e pode levar cerca de um minuto para voltar. O jogo atual tem timeout de 20 segundos: a primeira tentativa após inatividade pode falhar, mesmo com dados preservados. Para evento, abra `/ready` antes de começar e aguarde a resposta. Se precisar disponibilidade imediata após longos intervalos, use uma hospedagem que permaneça ativa. Não há promessa de custo zero para toda a solução. [Limitações do plano gratuito](https://render.com/docs/free)

## 6. Fazer o corte sem separar os rankings em duas fontes

Realize o corte em um intervalo em que o computador do evento não esteja sendo usado e os outros jogadores possam ser orientados a aguardar. Fechar somente o cliente local não bloqueia instalações normais que continuem online.

1. Guarde uma cópia do código atualmente publicado do Apps Script e de sua configuração. Tenha pronta a URL da API e uma implantação que responde `/ready`.
2. No Apps Script, adicione propriedades `MONGO_API_URL=https://SEU_SERVICO/exec` e `MIGRATION_MAINTENANCE=true`.
3. Substitua **apenas o backend de atendimento** pelo conteúdo de `server/mongodb/legacy/Bridge.gs`. Pode preservar `Export.gs` separado. Remova do projeto funções antigas de mutação para evitar executá-las por engano. Atualize a implantação existente para uma nova versão **mantendo a URL `/exec` antiga**.
4. Com manutenção ativa, a ponte devolve `busy`; as filas do jogo preservam envios pendentes. Agora nenhum cliente que use essa implantação escreve no Sheets. Execute a exportação final pelo arquivo auxiliar e valide o backup.
5. No banco de produção, execute `admin init` na versão correta, `import --check-db`, `import --apply`, `admin status` e `backup`, como no ensaio. Se já importou um ensaio no mesmo banco e houve alterações na origem, conflitos exigem reconciliação; não force sobrescrita. Use produção limpa para o corte definitivo.
6. Confira as contagens e rankings. Execute `npm run admin -- enable` no banco de produção.
7. Mude `MIGRATION_MAINTENANCE` para `false` nas propriedades do Apps Script. Não precisa embutir credenciais MongoDB no Google; a ponte só conhece a URL pública da API.
8. No Festival 0.5.0 existente, consulte ranking, jogue uma partida controlada, envie e confira sua chegada única ao MongoDB. Teste também um nome com acento e, se aplicável, a edição normal com uma conta migrada.
9. Deixe o Sheets como arquivo histórico, sem escrita. Não execute rotinas de limpeza ou nova temporada nele.

A ponte preserva compatibilidade com o executável já instalado, mas ainda depende de Apps Script e sua chamada de saída. A migração sem dependência Google termina ao distribuir builds apontando diretamente para a API. Não execute duas implantações antigas diferentes ainda gravando no Sheets sem inventariá-las no corte.

## 7. Retirar a dependência do Google nas próximas builds

Na branch de cada edição, altere somente `ranking.url` de `online.cfg` para `https://SEU_SERVICO/exec` e exporte uma nova build. O cliente já aceita HTTPS com JSON direto e seus arquivos locais continuam nos caminhos existentes. Não apague `online_ranking.json`, `festival_high_tech_mt.json` ou os históricos locais.

Instalações antigas continuam pela ponte e novas usam a API direta, ambas no mesmo MongoDB. Retire a ponte somente quando nenhuma instalação necessária depender dela. Atualizar somente `online.cfg` do repositório não altera a URL embutida no executável 0.5.0 que já foi distribuído.

## Backup, retorno e futuras temporadas

Execute `npm run backup` em máquina confiável e copie o JSON para armazenamento externo privado, com frequência adequada ao evento e antes de mudanças administrativas. Não dependa do disco temporário da hospedagem.

Se precisar retornar ao Sheets **antes** de receber partidas no MongoDB, mantenha manutenção e restaure a implantação anterior após conferir os dados. Se o MongoDB já recebeu resultados novos, pause envios e reconcilie esses resultados antes de voltar; simplesmente trocar o código de volta faria os novos dados desaparecerem da visão do jogo.

No MongoDB, a próxima temporada é aberta pela CLI: `npm run admin -- season 0.6`, usando a versão real da próxima publicação. Não é necessário fazer isso para ativar o Festival. A operação arquiva o top 100 por modo com nomes congelados e mantém os resultados originais. Não é exposta no endpoint público.

## O que conferir antes de considerar concluído

- Banco correto, versão ativa correta e backup completo guardado fora do projeto.
- Importação e restauração ensaiadas, contas migradas autenticando e nomes históricos preservados.
- Festival e Global separados, com contagens/rankings conferidos.
- Falha de rede preserva fila; reenvio não duplica resultado.
- API publicada, logs acessíveis, nenhuma credencial na build e nenhuma escrita restante no Sheets.
- Pelo menos uma partida enviada com sucesso pelo Festival 0.5.0 via ponte; nova build direta validada antes de retirar a ponte.

O que depende de você é criar/configurar Atlas e hospedagem, exportar os dados completos da sua conta, executar a importação no destino escolhido e publicar a ponte/builds. O código local permite fazer essas etapas depois, sem alterar agora a instalação em uso.
