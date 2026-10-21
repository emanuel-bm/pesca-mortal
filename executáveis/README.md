# Executáveis — Festival High Tech MT 0.5.0

Pacotes internos da branch `codex/festival-hightech`, baseados na main 0.5.0.

- **Windows x86_64:** execute o `.exe`.
- **Linux x86_64:** extraia o `.tar.gz` e execute o `.x86_64`. O executável solto também está disponível.
- **macOS Apple Silicon:** extraia o ZIP e abra `Pesca Mortal Festival.app`. Não inclui versão Intel. Usa assinatura ad-hoc, sem notarização Apple; a execução ainda precisa ser validada no Mac.

O perfil do festival é automático. A aba Global é somente leitura e o envio de uma partida publica apenas no Festival. No Boss Rush, somente vitórias entram no ranking, após preencher o nome e escolher Salvar e sair.

Antes do evento, atualize a implantação existente do Apps Script com o `Code.gs` desta pasta e execute `setupFestival` se necessário, mantendo a mesma URL. Não reinicie a temporada global 0.5. Consulte `../docs/festival-high-tech-mt.md` e `LEIA-ME.txt`.

Os binários são armazenados com **Git LFS**. Ao clonar ou trocar para esta branch, execute `git lfs install` e `git lfs pull` para baixar os arquivos completos. Confira a integridade com `SHA256SUMS.txt`.

Não foi criada release nem tag no GitHub. Esta pasta existe apenas nesta branch enquanto ela não for mesclada em outra.
