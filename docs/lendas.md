# Recordes por versão e Lendas

Os recordes são separados por X.Y em vX.Y.Z. Por exemplo, 0.3.1 e 0.3.3 competem no mesmo ranking 0.3; 0.4.0 começa outro ranking. O botão Lendas no canto superior direito de cada painel de Recordes abre a classificação global dentro do jogo, com seletores de versão e modo. Os três primeiros aparecem em cards: o primeiro recebe o maior destaque em dourado; o segundo tem destaque moderado em prata e o terceiro um detalhe discreto em bronze. A lista começa na quarta posição.

Lendas abre com a versão competitiva atual selecionada e seus recordes atuais, mesmo sem versões encerradas. O seletor também oferece as versões anteriores disponíveis. O quadro do perfil pessoal fica oculto nessa tela; os painéis de Recordes da tela inicial não repetem a versão já mostrada no rodapé.

O top 3 aparece em cards horizontais alinhados às colunas posição, nickname, level, tempo e eliminações. O recorde do jogador aparece sempre em uma linha com as mesmas colunas abaixo da lista, fora da área de rolagem e sem título ou versão repetida. Se o jogador estiver no top 100, essa linha repete seu resultado e sua posição; fora dele, mostra o melhor recorde local com um traço na posição. Sem recorde, os valores também mostram traços. Não há abas Global/Pessoal nem lista de partidas pessoais em Lendas.

Cada versão encerrada guarda até 100 jogadores por modo: 100 de Normal e 100 de Boss Rush. A lista global tem rolagem para consultar todos os resultados arquivados. Os campeões são os primeiros colocados de cada modo, seguindo os critérios de classificação atuais. O histórico pessoal preserva todas as partidas locais, separadas pela versão em que foram jogadas.

## Atualizar a implantação existente

1. Na planilha que já recebe os recordes, abra Extensões → Apps Script.
2. Substitua o código pelo conteúdo de `server/apps-script/Code.gs` deste projeto e salve.
3. Execute `setupRanking`. Isso preserva jogadores e recordes existentes, adiciona a coluna `competitive_version` em Records e cria Seasons. Resultados antigos sem versão são tratados como 0.3; o jogo faz a mesma atribuição no histórico pessoal e na fila offline.
4. Atualize a implantação web para usar a nova versão do script, mantendo a URL `/exec` atual em `online.cfg`.
5. Enquanto o jogo estiver em 0.3.Z, não execute a função de mudança de versão. Lendas ainda não terá um arquivo global de 0.3, pois essa classificação continua aberta.

O código local e os testes não atualizam automaticamente o serviço publicado na conta Google. Antes de distribuir o jogo com Lendas, publique o backend atualizado.

Se as consultas de 0.3 e 0.4 retornarem os mesmos recordes sem os campos `competitive_version`, `active_version` e `seasons`, a implantação ainda usa o backend anterior. O cliente 0.4 descarta esses dados para não incorporar os recordes de 0.3 à classificação atual. Execute os passos acima e, para o jogo 0.4, execute também `iniciarNovaVersaoCompetitiva`. Não apague manualmente Records nem marque seus resultados antigos como 0.4: a operação administrativa arquiva esses resultados como 0.3 antes de abrir a nova classificação. Depois, confira as abas `Lendas_0_3` e `Seasons` e recarregue o jogo; 0.3 deve aparecer no seletor de Lendas, enquanto 0.4 começa vazio até receber novos recordes.

## Publicar uma nova versão competitiva

Ao publicar 0.4.0, execute `iniciarNovaVersaoCompetitiva` pelo editor do Apps Script. O destino inicial no código é `0.4`; nas publicações seguintes, altere esse destino para o novo X.Y e salve antes de executar. A função administrativa não é exposta pela API pública do jogo.

A operação bloqueia envios durante a mudança, ordena os recordes globais, salva os 100 melhores de cada modo na aba `Lendas_0_3` com posição e nome do encerramento, registra 0.3 em Seasons, limpa Records e ativa 0.4. As abas Players e os arquivos anteriores são preservados. Patches como 0.4.1 não precisam dessa operação.

O nome do arquivo segue `Lendas_X_Y`. Seus campos são modo, posição, nickname, tempo, eliminações, nível e identificador público do jogador. Esse identificador permite reconhecer o jogador na classificação histórica mesmo após uma mudança de nome; arquivos antigos sem identificador usam o nickname como compatibilidade. Seasons guarda a versão encerrada e a data do encerramento. Records contém apenas os melhores resultados da versão ativa. Atualize a implantação do Apps Script para disponibilizar os identificadores nas consultas e nos novos arquivos.

Se houver falha no meio da mudança, execute novamente a mesma função com o mesmo destino. O marcador de transição impede envios enquanto a operação não terminar; a retomada preserva o arquivo já concluído. Reexecutar uma mudança concluída não apaga os recordes da nova versão. A função recusa voltar a uma versão anterior.

## Clientes antigos e partidas offline

Clientes antigos que não informam versão são tratados como 0.3. Depois do encerramento de 0.3, seus envios são recusados e não entram em 0.4. O cliente novo identifica a versão na fila offline, remove envios recusados definitivamente e preserva as partidas no histórico pessoal. Cada versão tem sua própria comparação de recordes; um resultado menor pode ser o primeiro recorde da versão nova.

Nomes históricos ficam congelados no encerramento. Renomear o perfil depois disso atualiza a classificação ativa, mas não muda as abas de Lendas. Arquivos globais já consultados ficam em cache para leitura offline.

## Verificação local

- `node server/apps-script/test.cjs`: valida arquivo de 100 por modo, migração de clientes antigos, nomes congelados, isolamento de versões e retomada de uma transição interrompida.
- `scripts/test_legends.gd`: valida migração local, fila por versão, isolamento de cache, novos recordes e controles de Lendas.
- `scripts/test_online_ranking.gd`, com o mock `node server/apps-script/test.cjs --serve`: valida envio e consulta pelo HTTP real, incluindo encerramento e leitura dos arquivos. A operação especial de mudança usada no mock existe somente no teste local.
- `scripts/test_layout.gd` e `scripts/test_menu_keyboard.gd`: verificam disposição das telas e navegação por teclado.
