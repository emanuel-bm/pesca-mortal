# Ativar o ranking global

O código do jogo e o backend estão preparados. Ainda é necessário publicar o Apps Script na conta Google do responsável. Sem a URL configurada, o jogo mostra o cadastro indisponível e não reserva um nickname. Não existe uma conta Google ou um serviço de produção criado automaticamente pelo projeto.

## Publicação inicial

1. Crie uma planilha privada no [Google Sheets](https://sheets.google.com). Não compartilhe a edição com os jogadores nem publique a planilha na web.
2. Na planilha, abra **Extensões → Apps Script**. Substitua o conteúdo de `Code.gs` pelo arquivo `server/apps-script/Code.gs` deste projeto e salve.
3. Execute a função `setupRanking` pelo editor. Autorize o script a acessar a sua planilha. Ele cria as abas `Players` e `Records` e guarda o ID da planilha nas propriedades do script.
4. Abra **Implantar → Nova implantação → Aplicativo da web**. Selecione execução como **você** e acesso por **qualquer pessoa**. Políticas de contas corporativas podem restringir essa opção; uma conta pessoal costuma ser mais direta. Somente a URL é pública, não a planilha.
5. Copie a URL terminada em `/exec` e coloque em `online.cfg`, no campo `url`. Nenhuma senha ou chave administrativa deve ir nesse arquivo.
6. Abra o jogo, cadastre um nickname e confirme que apareceu uma linha em `Players`. Faça um recorde e confirme a atualização em `Records` e no menu **Ranking global → Recarregar**. Use outra instalação para confirmar que o mesmo nickname é recusado, inclusive com maiúsculas diferentes.

Ao editar o backend, atualize a implantação para uma nova versão pelo gerenciador de implantações. A URL pode permanecer igual. Consulte a [documentação oficial](https://developers.google.com/apps-script/guides/web).

## Comportamento

- Nicknames têm 3–20 caracteres: letras ASCII, números e `_`; comparação ignora maiúsculas. Trocar o nickname mantém identidade e recordes e libera o nome anterior.
- Conta e token individual ficam em `user://online_ranking.json`. O token é gerado com aleatoriedade criptográfica antes do cadastro e o servidor armazena apenas seu hash. Repetir um cadastro após perder a resposta retorna a mesma conta. Perder esse arquivo implica perder acesso à identidade; não há recuperação automática nesta versão.
- Cadastro e mudança de nome exigem internet. Após cadastrar, o jogador pode jogar offline. A primeira execução pede o nickname antes de liberar o menu.
- A opção explícita **Jogar offline** da inicialização mantém o jogo local disponível sem cadastro. Nessa sessão não há pedidos HTTP; novos recordes ficam pendentes para uma sessão online posterior. A identidade é exigida antes da publicação, e não para jogar nesse modo offline.
- Cada partida continua registrada no histórico local. Somente um novo melhor resultado por modo entra na fila de envio, depois da gravação local bem-sucedida. Um resultado ainda melhor substitui o pendente. O servidor também compara o resultado com o já publicado.
- Novo recorde tenta enviar imediatamente. Falha de rede conserva o pendente, que será reenviado ao entrar no menu ou recarregar. Rejeição definitiva remove o pendente e informa o motivo; preserva o histórico local.
- Consulta ocorre ao entrar no menu e pelo botão **Recarregar**. A lista recebida permanece em cache, com data da consulta. Não há polling durante a partida.
- A planilha e as respostas públicas não incluem credenciais administrativas. As respostas de ranking não incluem o token ou seu hash. O Apps Script valida a identidade antes de alterar nickname/recorde e usa uma trava durante as operações.

## Validação `pesca-1`

O backend verifica tipos, valores finitos/não negativos, modo, personagem, motivo de encerramento, vitória dos chefões somente após 300 segundos, nível compatível com um teto conservador de XP e eliminações abaixo do máximo acumulado de surgimentos. No infinito, chefões aparecem a cada 90 segundos em ondas de 1, 2, 3…; peixes surgem em lotes a cada segundo, com taxa crescente. A fórmula inclui o primeiro lote e a margem de frame/precisão (o jogo limita `dt` a 0,05 s). O teto simultâneo de 1.000 inimigos só pode reduzir surgimentos; não é usado como teto de eliminações acumuladas.

Não há mínimo positivo universal de eliminações. O chefão derrotado no modo de vitória encerra a partida antes de incrementar `kills` no código atual. Testes de nível avançado não são publicados. Os limites são verificações de plausibilidade e não uma comprovação da legitimidade da partida.

Mudanças nas regras de spawn, XP, modos/personagens ou comparação precisam atualizar o backend e a constante `RULESET` do cliente conjuntamente. `config/version` continua sendo a versão do produto; `RULESET` identifica estas regras. O backend recusa versões de regras desconhecidas, em vez de aplicar limites de outra versão.

## Verificação local

Execute `node server/apps-script/test.cjs` para testes do backend com os serviços Google substituídos por doubles em memória. Para testar o HTTP real e os redirects, execute `node server/apps-script/test.cjs --serve` e, em outro terminal:

```powershell
& '.\.tools\godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script res://scripts/test_online_ranking.gd
```

Esses testes não publicam nem acessam uma planilha real. A validação na implantação Google deve ser feita após configurar a URL. O teste usa arquivos temporários próprios e um endpoint em `127.0.0.1`, aceito somente para testes locais; o serviço publicado usa HTTPS.
