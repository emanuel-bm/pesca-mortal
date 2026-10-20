# Recordes por versão e Lendas

## Decisões confirmadas

- A versão competitiva é X.Y em vX.Y.Z. Alterações de Z mantêm a classificação; alterações de X ou Y iniciam outra.
- Classificações globais e pessoais anteriores são preservadas em Lendas.
- O botão Lendas fica no canto superior direito do painel Recordes, ao lado do título.
- Lendas abre uma aba dentro do jogo, com seletor das versões competitivas anteriores.
- A aba destaca os campeões das versões encerradas mais recentes e permite consultar a classificação da versão selecionada.
- Campeão significa primeiro colocado global da versão competitiva encerrada.
- Os recordes existentes sem versão serão atribuídos a 0.3; não será tentada a reconstrução de versões anteriores.
- A classificação global encerrada fica congelada. Clientes antigos e envios offline atrasados não podem alterá-la; partidas pessoais continuam guardadas na versão em que foram jogadas.
- Os nomes globais históricos serão preservados como estavam no encerramento.
- Cada versão tem um campeão por modo: Normal e Boss Rush. Lendas permite escolher o modo e Global/Pessoal.
- O histórico global continuará na mesma planilha Google Sheets, com uma aba por versão competitiva encerrada, como Lendas_0_3. Cada linha identifica o modo.
- Cada aba histórica preserva somente os 100 melhores colocados por modo: até 100 de Normal e até 100 de Boss Rush. Não será preservada a classificação global além desse limite.
- Records continua recebendo os recordes da versão competitiva ativa.
- Uma função administrativa no Apps Script será executada ao publicar uma nova versão X.Y para arquivar a classificação anterior e ativar a nova. Alterações apenas de Z dispensam essa operação.

## Fatos encontrados

- O jogo está em 0.3.3. Os registros existentes não identificam sua versão competitiva.
- Há classificações separadas de Normal e Boss Rush, com critérios distintos.
- O backend guarda um melhor resultado por jogador e modo, substituindo o anterior.
- O nome mostrado no ranking vem do perfil atual do jogador.
- A fila de envios offline também não identifica versão competitiva.

## Escopo de implementação

- Identificar a versão competitiva nos registros pessoais, na fila offline, no cache e nas requisições ao servidor.
- Comparar novos recordes somente com os resultados da mesma versão competitiva e modo.
- Migrar os registros atuais sem versão para 0.3, preservando os dados existentes.
- Arquivar os 100 melhores por modo com posições e nomes do encerramento antes de iniciar outra classificação global.
- Impedir envios para versões globais encerradas e impedir que clientes antigos misturem seus resultados com a versão nova.
- Criar a aba Lendas no jogo com seleção de versão, modo e Global/Pessoal, além da vitrine dos campeões recentes.
- Preservar os critérios atuais de classificação e desempate.
- Documentar a atualização do Apps Script e a operação administrativa de mudança de versão competitiva.

## Implementação autorizada

Todas as decisões da entrevista foram respondidas e o usuário autorizou a implementação. A consulta dos até 100 resultados globais arquivados usa uma lista com rolagem dentro de Lendas.
