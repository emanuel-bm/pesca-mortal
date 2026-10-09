# Atualizações integradas

O próprio aplicativo abre `startup.tscn`, mostra apenas um indicador animado
e o texto **Verificando atualizações…**, consulta a última release pública do
GitHub e só depois carrega `main.tscn`. Título, versão e botões aparecem apenas
quando houver uma decisão após a consulta. Não há outro launcher para distribuir.
O Windows usa um auxiliar PowerShell oculto apenas durante a instalação,
pois o executável aberto não pode substituir a si mesmo.

- Versão atual: abre o menu com os recursos online.
- Nova versão: oferece **Baixar atualização** e **Jogar offline**.
- Falha de consulta (incluindo timeout, limite da API ou release inexistente):
  abre o menu offline automaticamente.
- Sem repositório configurado: oferece jogar offline.
- Jogar offline cancela o download, impede chamadas ao ranking e
  permite iniciar sem cadastro de nome. Recordes ficam na fila local para
  sincronização quando houver uma sessão online e um perfil cadastrado.
- O download não é obrigatório: a escolha offline está sempre disponível
  antes da instalação. A escolha vale para essa sessão; a próxima abertura
  consulta novamente.

## Conectar ao GitHub

O repositório público atual é
[emanuel-bm/pesca-mortal](https://github.com/emanuel-bm/pesca-mortal).
`updates.cfg` já está configurado para ele. A primeira versão é `v0.1.0`;
para as próximas atualizações, incrementar a versão e publicar uma nova
release seguindo os passos de exportação abaixo.

1. Criar o repositório público e enviar o projeto. Manter `.tools/` e `.godot/`
   fora do Git; distribuir builds como assets das Releases. Conferir antes
   que arquivos do servidor e configurações não contenham credenciais.
2. Em `updates.cfg`, preencher `repository="usuario/repositorio"`.
3. Incrementar `application/config/version` em `project.godot`, por exemplo
   `1.0.1`. Usar versões com três números, sem sufixos de pré-release.
4. Executar `powershell -NoProfile -File scripts/package_windows.ps1`.
5. Criar uma release publicada com tag `v1.0.1` e anexar
   `dist/Pesca-Mortal-Windows.zip`. Sempre usar esse mesmo nome do asset.
   A versão da tag precisa corresponder à versão exportada do jogo.
6. Distribuir essa primeira build aos amigos. As próximas releases poderão
   ser baixadas pelo próprio jogo.

Commits isolados não são atualizações. Releases em rascunho/pré-release não
entram nesse canal. A API precisa fornecer o `digest` SHA-256 do asset para
habilitar instalação automática; caso contrário, o botão abre o GitHub.
O código pode permanecer público junto com as releases, sem tokens no jogo.

## Instalação e limites

No Windows exportado, o jogo baixa o ZIP em `user://`, verifica SHA-256,
prepara o auxiliar e fecha. O auxiliar confere novamente o checksum, extrai
somente `Pesca Mortal.exe` da raiz do ZIP para um arquivo temporário na pasta
da instalação e espera o processo antigo terminar. Substitui o executável,
preserva backup até conseguir iniciar a nova versão e reabre o mesmo caminho.
O programa atualizado consulta novamente a release e abre o menu quando a
versão corresponde. Saves, nome, ranking local e preferências em `user://`
não são substituídos. O atalho continua apontando para o mesmo aplicativo.

Falhas mantêm/restauram o executável anterior e reabrem a tela com tentar
novamente/jogar offline. Detalhes ficam em `user://update-error.log`.
A pasta do jogo precisa permitir escrita. O pacote usa PCK embutido; builds
que precisem de DLLs ou outros arquivos devem ampliar o instalador antes da
distribuição. macOS, Linux e execução pelo editor oferecem download manual
no GitHub e jogar offline; a instalação automática atual é para Windows.

## Verificação

Executar importação headless, `scripts/test_startup.gd` e smoke test. O teste
de abertura simula respostas da API (incluindo falhas e download corrompido)
e verifica que o menu offline funciona sem cadastro. O teste PowerShell
`scripts/test_update_installer.ps1` instala um executável de teste e verifica
o caminho de erro, sem alterar a instalação real. Antes de publicar, testar
duas releases reais em outra máquina. O funcionamento ponta a ponta entre
duas versões distintas ainda precisa desse teste.

Referências: [GitHub Releases API](https://docs.github.com/en/rest/releases/releases?apiVersion=latest),
[Godot HTTPRequest](https://docs.godotengine.org/en/stable/classes/class_httprequest.html),
[Godot OS](https://docs.godotengine.org/en/stable/classes/class_os.html).
