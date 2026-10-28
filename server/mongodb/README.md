# Ranking com MongoDB

API Node.js 22+ e MongoDB com replica set (Atlas ou local). Atende os protocolos Global e Festival 0.5.0. Sem dependência de Atlas Data API. Começa com envios bloqueados até a importação/conferência.

O guia operacional é [Migrar os rankings](../../docs/guia-migracao-mongodb.md). O contrato e as decisões de transição estão no [plano](../../docs/plano-migracao-mongodb.md).

Produção: app Fly.io `pesca-mortal-api`, região `gru`, banco `pesca_mortal`. O endpoint público é `https://pesca-mortal-api.fly.dev/exec`. A importação da planilha foi conferida em 27/10/2026 e as gravações estão habilitadas. O arquivo local `.env` pode continuar apontando para homologação; para administrar produção, defina `MONGODB_DATABASE=pesca_mortal` explicitamente no ambiente do processo.

```powershell
cd server/mongodb
npm ci
Copy-Item .env.example .env
# Editar .env localmente: URI privada e nome do banco.
npm run admin -- init 0.5
npm start
```

`GET /health` verifica o processo. `GET /ready` confere acesso ao banco e inicialização. `POST /exec` e `POST /` aceitam o JSON do cliente atual e respondem JSON diretamente, sem redirect. Recusas e falhas transitórias retornam HTTP 200 com `ok:false`, por compatibilidade com o jogo. Configuração ausente resulta em `not_configured`, manutenção em `busy` e falha interna em `service_error`.

Comandos administrativos só existem na CLI, não na API pública:

`examples/sheets-backup.example.json` contém dados sintéticos apenas para ensaio; não importar em produção.

```powershell
npm run admin -- status
npm run admin -- disable
npm run import -- exports/backup.json
npm run import -- exports/backup.json --check-db
npm run import -- exports/backup.json --apply
npm run backup
npm run admin -- enable
npm run admin -- season 0.6
```

O primeiro comando de importação valida o arquivo sem conectar. `--check-db` confere conflitos em snapshot sem alterar o banco. `--apply` importa em transação, somente com envios desativados. Não sobrescreve dados diferentes existentes. Backup é JSON privado com contas e hashes; o mesmo importador restaura em banco vazio inicializado na versão correspondente. Os backups preservam os dados das cinco coleções do jogo e a versão ativa; configurações operacionais de hospedagem, permissões e credenciais são configuradas separadamente.

## Testes

```powershell
npm test
```

Os testes baixam um MongoDB 8.0.17 e iniciam um replica set descartável local. Não usam `MONGODB_URI` de produção. O primeiro download no Windows é grande (~756 MB); o binário fica em cache local, fora dos arquivos versionados. A suíte exercita transações reais, concorrência, idempotência, importação, restauração, HTTP e os auxiliares Apps Script com serviços simulados. O teste Godot é executado quando `GODOT_BIN` aponta para a engine, ou quando a engine portátil está na localização padrão deste projeto. Em outros ambientes ele aparece como ignorado; configurar `GODOT_BIN` para validar o cliente real.

## Operação

- Só a API recebe a URI e o usuário do MongoDB. O jogo recebe apenas a URL HTTPS.
- Índices únicos garantem identidades, nomes e partidas sem duplicação. Transações coordenam envios, manutenção e fechamento de temporada; o fechamento conserva os recordes originais.
- As escritas atualizam uma revisão compartilhada de configuração, apropriada ao baixo volume atual. Isso serializa mutações e não foi projetado para alto volume.
- As leituras filtram por evento/versão e usam a ordenação JavaScript legada antes de selecionar o top 100. Por preservar o desempate atual, ainda carregam as entradas correspondentes e nomes globais em memória. Reavaliar paginação/ordenação por índice se o banco crescer substancialmente.
- O limitador simples permite 120 pedidos por minuto por conexão de origem/IP de transporte. Não confia em `X-Forwarded-For`. Atrás de proxy, o limite pode ser compartilhado; configurar proteção no provedor para escala/abuso. Não autentica a legitimidade de partidas do Festival.
- Logs contêm identificador da requisição, operação, categoria/código seguro e duração. Não contêm payloads, nomes, tokens, URI ou stack com dados privados. Relacione o cabeçalho `X-Request-ID` aos logs.
- Inicializar os índices e a configuração é uma operação explícita (`admin init`). Iniciar o servidor não importa dados nem escolhe uma temporada automaticamente.
- Criar backups em máquina confiável e copiar para armazenamento externo; o disco de hospedagem de um container pode ser descartável.

## Arquivos de transição

- `legacy/Export.gs`: adicionar como arquivo separado ao projeto Apps Script existente para exportar as abas completas a um JSON privado no Drive; não substituir o backend.
- `legacy/Bridge.gs`: substituir o backend somente no corte. Encaminha pedidos à nova API, preservando a URL antiga da build 0.5.0. Não grava no Sheets.
- Nenhum dos dois é publicado automaticamente pelos comandos Node.
