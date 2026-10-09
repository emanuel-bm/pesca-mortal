# Pesquisa: ranking global simples

Consulta em 9 de outubro de 2026. Proposta de arquitetura; nenhum recurso online ou código do jogo foi implementado.

## Recomendação

Para um grupo inicial de aproximadamente dez jogadores, a opção mais simples de administrar visualmente é **Google Sheets privado + Apps Script publicado como web app**. A planilha guarda os jogadores e os melhores resultados; o script recebe os pedidos do jogo, verifica a identidade, atualiza somente um recorde melhor e devolve o ranking em JSON. Minha avaliação de simplicidade considera o tamanho do grupo e a possibilidade de corrigir resultados na própria planilha; não é uma garantia de desempenho do provedor.

**Supabase** é a alternativa preferível se já quisermos um banco com autenticação e regras de acesso, aceitando um pouco mais de configuração. Não há necessidade de servidor dedicado ou conexão em tempo real para qualquer uma dessas opções.

## Como os dados saem do computador

O Godot faz uma requisição HTTPS para uma URL pública do serviço. O serviço grava no armazenamento central, que existe independentemente de qualquer computador dos jogadores. JSON pode ser o formato da mensagem sem precisar ser o arquivo de armazenamento. O Godot tem `HTTPRequest` e documentação com envio de JSON e métodos HTTP. [Documentação do Godot](https://docs.godotengine.org/en/stable/tutorials/networking/http_request_class.html)

Fluxo proposto:

1. Primeiro uso: jogador escolhe o nickname; serviço reserva o nome e cria uma credencial individual.
2. Fim da partida: jogo salva localmente e envia apenas seu resultado. Serviço compara com o melhor registrado.
3. Abertura do menu e botão “Recarregar”: jogo consulta a lista, sem conexão persistente.
4. Sem internet: jogo mantém a última lista e o recorde pendente; tenta enviá-lo na próxima entrada no menu. Mostrar horário da última consulta evita confundir o cache com o ranking atual.

As etapas e nomes são proposta de produto, não implementação existente. A inscrição inicial precisa estar online para garantir a exclusividade do nickname.

## Opções pesquisadas

| Opção | Onde ficam os dados | Envio pelo jogo | Avaliação para este projeto |
| --- | --- | --- | --- |
| Sheets + Apps Script | Planilha privada na conta Google do responsável | HTTPS GET/POST para web app | Melhor MVP para dez pessoas; editor visual pronto. Precisamos escrever as regras de nickname, token e atualização. |
| Supabase | PostgreSQL hospedado | API REST, autenticação e função no banco/servidor para registrar recorde | Melhor caminho para evoluir; unicidade e permissões podem ficar no banco. |
| Firebase Realtime Database | Banco JSON hospedado | REST HTTPS e Firebase Authentication | Próximo da ideia de JSON compartilhado; regras de identidade e reserva do nickname precisam de atenção. |
| Cloudflare Workers + D1 | Banco SQL D1 | API HTTPS escrita em um Worker | Backend pequeno e controlado; mais preparação técnica que a planilha. |
| JSON + endpoint em hospedagem própria | Arquivo persistente no servidor | Endpoint PHP ou equivalente | Viável se já existe hospedagem; exige permissões, gravação protegida e backup. Não basta publicar um JSON estático. |

### Google Sheets + Apps Script

Web apps do Apps Script usam `doGet` e `doPost`, podem executar como o proprietário e disponibilizam URL de implantação. Isso permite manter a planilha privada e deixar o script autorizado pelo responsável fazer as alterações. A configuração de acesso público pode depender das políticas da conta Google/Workspace. [Web Apps](https://developers.google.com/apps-script/guides/web)

O Content Service devolve JSON. Suas respostas usam redirecionamento para `script.googleusercontent.com`; o cliente precisa seguir redirecionamentos. Isso deve ser verificado na integração Godot. [Content Service](https://developers.google.com/apps-script/guides/content)

Usar duas abas: jogadores (`player_id`, `nickname`, `nickname_key`, hash da credencial) e recordes (`player_id`, modo, tempo, eliminações, personagem, versão, data do servidor). A resposta pública inclui somente campos de ranking. Nunca publicar a aba com credenciais.

Ao cadastrar ou comparar/gravar recorde, adquirir `LockService.getScriptLock()` com `tryLock` ou `waitLock` e liberá-lo ao terminar. O serviço é específico para proteger recursos compartilhados. Não precisaríamos montar infraestrutura própria de concorrência. [Lock Service](https://developers.google.com/apps-script/reference/lock)

Há cotas e limites, sujeitos a alterações; atingir um limite interrompe a execução. Dez jogadores com consultas ocasionais sugerem carga baixa, mas não permitem prometer disponibilidade irrestrita. O limite de `URL Fetch` documentado refere-se a chamadas de saída feitas pelo script, não é uma cota de requisições recebidas pelo jogo. [Cotas oficiais](https://developers.google.com/apps-script/guides/services/quotas)

### Supabase

Gera uma API REST sobre PostgreSQL. Regras RLS restringem quais linhas cada usuário pode acessar; nickname normalizado com restrição `UNIQUE` garante a exclusividade no armazenamento. Uma função de registro deve comparar e gravar o melhor resultado no servidor, em uma operação protegida. [API REST](https://supabase.com/docs/guides/api), [RLS](https://supabase.com/docs/guides/database/postgres/row-level-security), [Constraints PostgreSQL](https://www.postgresql.org/docs/current/ddl-constraints.html)

Autenticação anônima oferece identidade sem solicitar email, com possibilidade de vincular um método de login depois. Perder a sessão ou trocar de dispositivo impede voltar a essa identidade sem vínculo/recuperação; o nickname sozinho não é prova de propriedade. Chaves administrativas/service role não devem ir no jogo. [Anonymous Sign-Ins](https://supabase.com/docs/guides/auth/auth-anonymous), [RLS](https://supabase.com/docs/guides/database/postgres/row-level-security)

Na consulta, o plano gratuito oferecia banco de 500 MB e projetos podiam ser pausados após uma semana de inatividade. A capacidade é ampla para a proposta, mas a pausa importa para um grupo que joga esporadicamente. [Preços Supabase](https://supabase.com/pricing)

### Firebase

O Realtime Database permite ler e gravar JSON pela API REST; qualquer ambiente que suporte HTTPS pode utilizá-la. O acesso é controlado por regras e tokens individuais do Firebase Authentication. Existe criação de usuário anônimo pela API REST de autenticação. Não deixar escrita pública irrestrita, nem embutir credenciais de serviço no executável. [REST do banco](https://firebase.google.com/docs/reference/rest/database), [Autenticar REST](https://firebase.google.com/docs/database/rest/auth), [Auth REST](https://firebase.google.com/docs/reference/rest/auth)

A API dispõe de gravações condicionais usando ETag/If-Match, úteis para reservar um nickname sem sobrescrever a reserva de outro jogador. A implementação do melhor recorde ainda deve considerar operações simultâneas e tentativas repetidas. [Referência REST](https://firebase.google.com/docs/reference/rest/database)

O plano Spark contém franquias gratuitas; conferir os limites do Realtime Database, não os de Firestore, na escolha e na implantação. [Preços Firebase](https://firebase.google.com/pricing)

### Workers + D1

O Worker faz a ponte HTTPS e consulta D1 através de binding. D1 utiliza semântica SQL do SQLite; tabelas de jogadores/recordes são adequadas à proposta. Guardar credenciais do provedor no backend, com tokens individuais para o jogo. [Consultar D1](https://developers.cloudflare.com/d1/best-practices/query-d1/)

Na consulta, a franquia D1 Free era de 5 milhões de linhas lidas/dia, 100 mil escritas/dia e 5 GB totais. Worker também tem suas próprias cotas; esses números não equivalem a pedidos HTTP. [Preços D1](https://developers.cloudflare.com/d1/platform/pricing/), [Preços Workers](https://developers.cloudflare.com/workers/platform/pricing/)

## Nickname único e recuperação

Proposta mínima: servidor normaliza o nome, por exemplo removendo espaços nas extremidades e comparando sem diferenciar maiúsculas/minúsculas. O nome para exibição permanece separado. A operação “verificar se existe + reservar” precisa ser indivisível, usando lock na planilha ou unicidade no banco.

Para Sheets, o servidor cria um token aleatório individual de alta entropia, devolvido uma única vez. Jogo guarda `player_id` e token no armazenamento local; servidor guarda apenas um hash do token. Todos os envios posteriores devem comprovar a identidade antes de alterar o resultado. UUID/ID identifica uma conta, mas não substitui segredo de autenticação.

Oferecer um código de recuperação separado ou exportação da credencial. Para dez pessoas, recuperação manual pelo administrador também é uma escolha razoável, com verificação combinada fora do jogo. Reinstalar o jogo sem cópia não deve liberar automaticamente o nickname nem permitir tomar a conta usando apenas o nome. Em Supabase/Firebase, utilizar sessões e refresh tokens do sistema de autenticação em lugar de reinventar esse mecanismo.

## Regras específicas deste jogo

Leitura de `scripts/run_history.gd`:

- Infinito: maior tempo; empate decidido pelo maior número de eliminações.
- Chefões: somente partidas com motivo `won`; menor tempo; empate pelo maior número de eliminações.
- O histórico local continua útil; ranking global deve manter o melhor resultado de cada jogador por modo.

Padronizar a precisão do tempo enviado (por exemplo milissegundos inteiros) e incluir versão/temporada do ranking, pois mudanças de equilíbrio podem alterar o significado de um recorde. Não misturar automaticamente resultados de modos diferentes.

## Limites da simplificação

Consultar somente na abertura ou no botão reduz tráfego de leitura. Não impede duas pessoas de cadastrarem o mesmo nickname ou enviarem resultados simultaneamente. A pequena proteção de gravação continua necessária: lock, unicidade ou atualização condicional. [Lock Service](https://developers.google.com/apps-script/reference/lock), [Constraints PostgreSQL](https://www.postgresql.org/docs/current/ddl-constraints.html), [REST Firebase](https://firebase.google.com/docs/reference/rest/database)

Credenciais individuais impedem um jogador comum de enviar em nome de outro. Não provam que um recorde foi obtido legitimamente: executável e save locais podem ser alterados e a requisição pode ser reproduzida. Para um grupo conhecido, validar tipos/limites, aceitar somente melhora e permitir correção administrativa é a política escolhida para o MVP.

Não distribuir senha da conta Google, token de GitHub, chave de serviço Firebase, chave administrativa Supabase ou token administrativo Cloudflare. A URL da API pode ser pública; a autorização para modificar um jogador precisa ser individual. Um JSON público em GitHub Pages ou site estático resolve leitura, mas não reserva nickname nem recebe envios sozinho.

## Plano sugerido para uma futura implementação

1. Escolher Sheets + Apps Script para o primeiro grupo ou Supabase se crescimento já for prioridade.
2. Definir modos, desempate, normalização de nickname e recuperação.
3. Criar operações de cadastro, envio de recorde e consulta pública.
4. Integrar no Godot cadastro, cache, fila de envio e botão de recarga.
5. Verificar dois cadastros iguais simultâneos, token incorreto, recorde pior, repetição de envio e indisponibilidade de internet.

As etapas são planejamento; dependem da escolha do usuário para implementação posterior.

## Complemento: cliente adulterado e token invisível

Não mostrar o token na interface evita divulgação acidental; não o torna inacessível ao dono do computador. Se o jogo utiliza uma credencial para fazer o pedido, um cliente modificado pode utilizá-la também. Um segredo único embutido no executável de todos os jogadores é especialmente inadequado: pode ser extraído e reutilizado. O RFC de autenticação para aplicações nativas explica que segredos estáticos distribuídos no aplicativo não constituem autenticação confiável do aplicativo. Essa conclusão se aplica aqui como princípio de arquitetura, embora o documento trate de OAuth. [RFC 8252, seção 8.5](https://www.rfc-editor.org/rfc/rfc8252#section-8.5)

Um token individual deve autorizar somente a identidade correspondente, nunca acesso administrativo. HTTPS, armazenamento protegido do sistema operacional, sessões com expiração e revogação ajudam a proteger a conta, mas não comprovam que o próprio jogador respeitou as regras do jogo.

Nem Firebase nem Supabase impedem automaticamente pontuações falsas. Regras Firebase/RLS Supabase protegem acesso e validam campos; um pedido bem formado com token válido ainda pode declarar um resultado inventado. A documentação de rankings PlayFab alerta que permitir atualização pelo cliente autoriza valores arbitrários. Mover apenas a gravação para uma função no servidor, mantendo confiança irrestrita no número recebido, preserva esse problema. [Regras Firebase](https://firebase.google.com/docs/database/security), [RLS Supabase](https://supabase.com/docs/guides/database/postgres/row-level-security), [Estatísticas PlayFab](https://learn.microsoft.com/en-us/xbox/playfab/community/leaderboards/tournaments-leaderboards/using-player-statistics)

Decisão do usuário: **simulação no servidor e replay simulado estão completamente descartados**, inclusive como evolução recomendada. A arquitetura aceita a limitação do resultado calculado localmente e aplica controles proporcionais ao pequeno grupo.

Camadas aprovadas ou opcionais dentro desse escopo:

1. **MVP entre conhecidos:** identidade individual, somente melhores resultados, limites plausíveis, registros para auditoria e remoção administrativa. Bloqueia alterações de outras contas e erros; não bloqueia toda trapaça.
2. **Validação de sessões:** servidor cria sessão e mede duração; recebe eventos/resumo e rejeita inconsistências. Ajuda a detectar resultados impossíveis, mas eventos enviados pelo cliente também podem ser fabricados. A Microsoft recomenda avaliar plausibilidade e tempo dos relatos de rodada como proteção intermediária. [Práticas PlayFab](https://learn.microsoft.com/en-us/xbox/playfab/pricing/consumption-best-practices)
3. **Telemetria para revisão, opcional:** resumo de duração, nível, personagem, versão e progressão para ajudar a revisar anomalias. Não reexecutar a partida. Tratar sinais suspeitos como motivo para revisão, não prova automática de fraude.

Firebase App Check complementa a autenticação com atestação do aplicativo/dispositivo. A própria documentação afirma que não elimina todos os vetores de abuso. Para um executável Godot de desktop, não presumir suporte pronto equivalente a Android/iOS: um provedor personalizado exige integração e método de atestação próprios. App Check não é prova de execução legítima da partida. [App Check](https://firebase.google.com/docs/app-check)

## Complemento: pausa do Supabase

Projetos Free podem ser pausados após pouca atividade durante sete dias; não precisa ser ausência absoluta de acessos. A documentação não promete despertar automático com o próximo pedido do jogo: o fluxo documentado é o proprietário abrir o Dashboard, selecionar o projeto e confirmar **Resume project**. Portanto, não contar com retorno automático transparente para o jogador. [Project Pausing](https://supabase.com/docs/guides/platform/free-project-pausing)

Atividade suficiente enquanto o projeto ainda está ativo pode evitar a pausa; isso é diferente de retomar um projeto já pausado. Planos pagos não sofrem pausa por inatividade. Para um grupo que passa semanas sem jogar e deseja ranking disponível sem intervenção do administrador, considerar Firebase, Sheets ou Workers+D1, conforme suas cotas, ou contratar Supabase pago. A escolha do armazenamento não resolve por si só a segurança da pontuação. [Project Pausing](https://supabase.com/docs/guides/platform/free-project-pausing)

## Pesquisa complementar: mercado e fóruns

**Unity Cloud Code:** documentação exemplifica validação de intervalos de pontuação e medição de início/fim de uma ação no servidor, além de controle de acesso para bloquear gravação direta pelo cliente. Serve como referência de arquitetura: funções centrais autorizam e validam pedidos sem executar o jogo. Não implica trocar Godot por Unity. [Prevenção de cheats](https://docs.unity.com/en-us/cloud-code/cheat-prevention), [Controle de acesso](https://docs.unity.com/en-us/cloud-code/server-access-control)

**Steam Leaderboards:** a configuração `Trusted` restringe gravações à Web API do backend; é um exemplo real de centralizar a permissão de escrever o ranking. Isso evita que a API do jogo escreva diretamente, mas o backend ainda precisa decidir quais pedidos aceitar. É uma opção futura se houver distribuição Steam; não é motivo para publicar o jogo na Steam apenas para dez jogadores. [Steamworks](https://partner.steamgames.com/doc/features/leaderboards)

**Anti-Cheat Toolkit (ACTk):** produto para Unity com tipos ofuscados, proteção de saves e detectores de alterações de memória/velocidade/injeção. O próprio fornecedor afirma que não torna um jogo totalmente protegido. É exemplo de camada contra ferramentas comuns, não integração pronta para nosso Godot. Não comprar/adaptar agora: primeiro resolver identidade e controles do backend. As afirmações de eficácia são do fornecedor, não resultado de avaliação independente. [Produto oficial](https://codestage.net/products/anti-cheat-toolkit/)

**Easy Anti-Cheat:** serviço da Epic integrado ao EOS, com prevenção e detecção no cliente. Exige integração própria e avaliação de compatibilidade; não oferece prova automática de que o tempo/eliminações enviados ao nosso ranking são verdadeiros. Para dez jogadores, minha avaliação é que o esforço é desproporcional ao MVP. [EAC](https://www.easy.ac/), [licenciamento](https://www.easy.ac/licensing)

**Discussões em fóruns:** desenvolvedores relatam combinar identidade, hashes, variáveis isca/honeypots, revisão e exclusão de resultados ou separação de contas suspeitas. São experiências e sugestões comunitárias, não garantias de segurança nem validação específica do nosso jogo. [Discussão sobre rankings](https://www.reddit.com/r/gamedev/comments/1oo6j34/), [discussão sobre cheats](https://www.reddit.com/r/gamedev/comments/ne66yl/). Conteúdo consultado pelo agente principal; nesta rodada, as duas URLs retornaram timeout ao agente que atualizou a nota.

Um hash calculado pelo próprio cliente detecta corrupção acidental ou alterações simples somente sob determinadas condições; um cliente adulterado pode recalculá-lo ou mentir sobre a verificação. Ofuscação/encriptação de variáveis e saves aumenta o trabalho para atacar, mas não cria autoridade sobre o resultado. Honeypots também dependem de o código de detecção executar. Se adotados futuramente, esses sinais devem complementar revisão e moderação; não substituir autenticação ou justificar banimento automático isoladamente.

## Plano recomendado após as decisões

1. Identidade individual, nickname único normalizado e recuperação; cadastro por convite é opcional para o primeiro grupo.
2. API central controla todas as alterações. Jogador pode enviar somente seus próprios resultados; nenhuma chave administrativa no jogo.
3. Servidor valida formato, números finitos, intervalos, modo, versão, vitória nos chefões, melhor resultado e repetição de envio; limita frequência e protege reserva/gravação simultânea.
4. Registrar envios e decisões para auditoria; permitir ocultar, remover e corrigir resultados via administrador, com possibilidade de revisão de falsos positivos.
5. Consultar na abertura do menu e no botão; cache local e envio pendente quando offline.
6. Futuramente, somente se necessário: início/fim de sessão medidos pelo servidor e telemetria resumida para revisão.

Esta recomendação substitui a direção anterior de segurança mais complexa. Não há simulação de jogo, reexecução de replay ou implementação nesta pesquisa.
