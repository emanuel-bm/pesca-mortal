# Plano de migração dos rankings para MongoDB

## Objetivo e decisões propostas

Migrar os rankings Global, Festival e Lendas do Google Sheets para MongoDB Atlas, preservando contas, resultados, nomes históricos e partidas pendentes nos computadores. Este documento é um plano; não cria infraestrutura, não altera a implantação e não migra dados.

Arquitetura: Godot → API HTTPS própria → MongoDB Atlas Free. Implementação da API: Node.js com módulos JavaScript e driver oficial MongoDB, aproveitando os validadores e os testes atuais do backend. A implementação inicial usa JavaScript para executar diretamente no Node, sem etapa de compilação. Um serviço atende ambas as edições com separação explícita de evento e versão competitiva.

A antiga Atlas Data API e os HTTPS Endpoints do App Services chegaram ao fim de vida em 30/09/2025. Portanto, não serão dependências. Se a oferta mencionada pelo responsável for outra API, verificar seu nome e documentação antes de escolher a hospedagem. A Atlas Administration API administra infraestrutura; não substitui a API de partidas do jogo. [Aviso oficial](https://www.mongodb.com/docs/api/doc/atlas-app-services-admin-api-v3/group/endpoint-data-api)

O Atlas Free oferece aproximadamente 0,5 GB incluindo índices e limite de 100 operações por segundo; para o volume informado de cerca de uma chamada por minuto, há margem inicial ampla, sujeita ao tamanho dos documentos e às consultas. A hospedagem da API é um recurso separado: custo zero total depende da oferta e dos limites do provedor escolhido. Verificar também conexões, suspensão por inatividade e opções de backup vigentes antes da publicação. [Limites oficiais](https://www.mongodb.com/docs/atlas/reference/free-shared-limitations/)

## 1. Contrato e inventário antes de implementar

- Congelar exemplos de pedidos e respostas reais do Festival 0.5.0 e da edição normal. Preservar `register`, `rename`, `submit`, `ranking`, `legends`, `ok`, códigos de erro, `event_id`, `competitive_version`, `active_version` e `seasons` quando aplicáveis.
- Manter regras de validação, ordenação, desempate, limite de 100 por modo e compatibilidade das regras `pesca-1` e `pesca-2`. O Festival aceita partidas distintas com o mesmo nome e resultados inferiores; o Global mantém o melhor por jogador, modo e versão.
- Registrar a versão efetivamente implantada, ID da planilha e propriedades relevantes do script. Não inferir a versão ativa somente das linhas de Records.
- Definir quais instalações precisam continuar funcionando sem atualização. O endereço em `online.cfg` acompanha a build exportada; alterar apenas o arquivo do repositório não muda executáveis distribuídos.

Entrega: contrato HTTP e inventário de origem aprovados por testes de compatibilidade.

## 2. Estrutura de dados

| Coleção | Conteúdo e identidade |
| --- | --- |
| `players` | `player_id`, nickname atual, chave normalizada e hash do token. Índices únicos de `player_id`, `nickname_key` e `token_hash`. |
| `best_records` | Melhor resultado global por `(player_id, competitive_version, mode)`, com índice único nessa combinação. |
| `festival_runs` | Todas as partidas aceitas; índice único `(event_id, run_id)`. Nome, modo, tempo, eliminações, nível e regras preservados. |
| `seasons` | Versão competitiva, estado aberta/fechando/fechada e data de encerramento. Versão única. |
| `legend_entries` | Snapshot histórico com nome congelado e posição; índice único `(competitive_version, mode, position)`. |
| `service_config` | Versão global ativa e eventos habilitados; não misturar configuração com os resultados. |
| `migration_runs` | Identificador da importação, origem, contagens, checksums e resultados da conferência. |

Criar índices de leitura alinhados ao filtro de evento/versão/modo e à ordenação de cada modo: tempo descendente no Normal, ascendente no Boss Rush, eliminações descendentes e desempate por nome compatível com o comportamento atual. Definir explicitamente collation ou chave de ordenação para nomes com acentos do Festival.

Fechar uma temporada muda seu estado e produz o snapshot de Lendas; não apaga os resultados antigos. Tornar a operação retomável e impedir envios para uma temporada em fechamento. Coordenar fechamento e envios atomicamente, com transação se suportada pelo ambiente validado; testar falhas e corridas antes de adotar a estratégia.

## 3. API e segurança

- Manter inicialmente um único endpoint POST compatível com o protocolo existente, evitando reescrever a interface do Godot.
- Reutilizar SHA-256 dos tokens existentes para que contas migradas continuem autenticando. Importar hashes, nunca exigir tokens individuais dos jogadores. Não trocar o algoritmo durante essa migração.
- Credenciais MongoDB ficam somente no servidor, em variáveis secretas. Usuário do banco com permissões limitadas ao banco da aplicação; acesso de rede configurado para a hospedagem. [Conexão ao Atlas](https://www.mongodb.com/docs/atlas/connect-to-database-deployment/)
- Usar operações atômicas e índices únicos para cadastro, reserva de nome e comparação de recordes. Resolver concorrência e tentativa repetida sem sobrescrever um resultado melhor nem duplicar partida.
- Validar payload, números, regras, versões e nomes antes de gravar. Manter os códigos de recusa definitiva usados pela fila atual; erros transitórios devem conservar a partida pendente.
- Festival continua sem conta individual, conforme o produto atual. Uma chave embutida no executável não é segredo; definir proteção contra abuso e limites proporcionais, sem anunciar prova de legitimidade das partidas.
- Registrar código interno do erro, identificador da requisição, duração e operação, sem tokens, hashes ou conteúdo pessoal desnecessário. Cliente recebe mensagem útil sem detalhes internos.
- Reutilizar conexões MongoDB com pool pequeno. Implementar verificação de saúde e prontidão, timeouts e respostas JSON consistentes, inclusive quando o banco estiver indisponível.

## 4. Recuperar e importar os dados

1. Exportar o arquivo original e cópias das versões históricas necessárias. Preservar Players, Records, Seasons, todas as Lendas e Festival High Tech MT, mais configuração do script. Guardar backup fora do MongoDB.
2. Fazer inventário por aba, modo, versão e evento. A consulta pública que retornou 23 resultados Normal e 1 Boss Rush comprova dados acessíveis naquele momento, mas é limitada ao top 100 por modo e não serve de backup completo.
3. Se as abas válidas estiverem em versões diferentes, consolidar em uma área de preparação, mantendo origem e timestamp. Não restaurar sucessivamente o original para fazer a junção.
4. Importar primeiro em banco de homologação, com modo de simulação que apenas valida e relata problemas. Colocar conflitos e linhas inválidas em relatório; não descartá-los silenciosamente.
5. Preservar IDs, `run_id`, tempos e nomes históricos. Atribuir versão legada 0.3 somente segundo a mesma regra do backend atual. Deduplicar por identidade, nunca apenas por nickname.
6. Conferir referências Players–Records, duplicatas de nome normalizado, contagens, melhores resultados e classificação completa. Não transformar snapshots de Lendas em partidas completas que não existem na fonte.
7. Tornar a importação idempotente: repetir o mesmo lote não duplica nem substitui resultados mais recentes. Reimportação de arquivo com mesmo ID e conteúdo divergente deve gerar conflito explícito.

Entrega: relatório de diferenças e backup verificado antes de qualquer troca de produção.

## 5. Compatibilidade com o Festival 0.5.0 instalado

Há duas rotas possíveis:

- Preferida para a migração definitiva: distribuir nova build com a URL HTTPS da nova API, preservando os arquivos locais e as filas existentes.
- Se a build fixa precisar continuar funcionando: manter temporariamente a URL `/exec` e substituir seu atendimento por uma ponte que encaminha o JSON à API e devolve a resposta compatível. A API precisa responder JSON diretamente, e a ponte deve encaminhar recusas como dados compatíveis, sem converter tudo em falha genérica. Validar o fluxo com os redirecionamentos atuais do cliente.

A ponte ainda depende de Apps Script e de chamadas de saída UrlFetch; é uma etapa temporária, não uma remoção completa da dependência Google. Após o corte, ela usa MongoDB por meio da API e deixa de escrever no Sheets. Todos os clientes devem convergir para a mesma fonte para evitar resultados divergentes.

## 6. Testes e critérios de aceite

- Contrato executado contra os dois backends com fixtures equivalentes e respostas públicas comparadas.
- Testes com MongoDB real de homologação para unicidade, escritas simultâneas, troca de nickname, melhor recorde, retry após gravação com resposta perdida e isolamento entre Festival e Global.
- Executável Festival 0.5.0 testado com a ponte caso seja necessária; nova build testada diretamente na API. Cobrir cadastro normal, Unicode do Festival, Boss Rush, Lendas, treino excluído e partidas offline.
- Falha de rede, timeout, indisponibilidade do banco e retorno do serviço: fila local permanece íntegra e não duplica resultados. Identificar recusa definitiva separadamente.
- Importação repetida, conflitos, fechamento de temporada interrompido e restauração de backup devem passar em homologação.
- Perfil e autenticação existentes funcionam; ranking e nomes históricos correspondem ao conjunto migrado; nenhum segredo de banco aparece na build.

## 7. Corte e retorno

1. Publicar API e banco de produção, com índices, segredos, logs e backup definidos; executar consultas de conferência.
2. Em janela curta, bloquear envios na origem com resposta transitória compatível. Manter partidas nos arquivos locais; não descartar pendências.
3. Fazer exportação final, importar o delta e repetir as conferências. Registrar o ponto de corte.
4. Trocar o atendimento da URL antiga para a ponte, se necessária, e publicar/configurar as novas builds para a API direta. Evitar qualquer período com duas fontes independentes aceitando escritas.
5. Testar uma partida controlada e verificar sua chegada única no MongoDB e sua consulta no jogo. Acompanhar erros, latência e fila até validar operação normal.
6. Preservar Sheets como arquivo histórico somente leitura. Remover a ponte apenas quando as instalações que precisam dela tiverem sido atualizadas.

Retorno: se não houve escritas no MongoDB, reativar a origem após conferir o estado. Se houve, pausar envios, exportar e reconciliar essas novas partidas antes de voltar ao Sheets. Reapontar a URL sem reconciliar causaria perda aparente de resultados. Manter backups externos e ensaiar a restauração antes do corte.

## Ordem de execução e pendências

Sequência: contrato e inventário → API e modelo → testes de integração → importador e homologação → backup e conferência → corte → acompanhamento → retirada da ponte.

Não é necessário acessar a conta Google para começar contrato, API e testes. A recuperação/importação depende posteriormente dos dados completos. Antes de publicar, confirmar a oferta MongoDB mencionada pelo responsável, a hospedagem da API, o acesso ao Atlas, a política/custo de backup e a necessidade de manter o executável 0.5.0 sem atualização. Credenciais serão configuradas no ambiente de hospedagem, não em mensagens nem no repositório.
