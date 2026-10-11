# Notas oficiais e atualizações menores

A tela aprovada está integrada ao jogo. Clicar no `?` ao lado da versão abre
o histórico oficial das releases públicas estáveis do GitHub, com paginação,
em ordem de publicação. ESC ou Voltar retorna ao menu. O painel permanece
centralizado e o botão fica independente no canto inferior direito.

Ao abrir as notas em uma sessão online, o jogo consulta o GitHub e mantém uma
cópia local, com intervalo de cinco minutos entre consultas bem-sucedidas.
Sem conexão, mantém o conteúdo salvo e o histórico incluído na build.
Nenhum token é necessário. O texto remoto é escapado antes da apresentação;
não executa comandos nem interpreta links como ações.

O processo obrigatório para atualizar as notas a cada release e preparar o
histórico offline está no README. `scripts/sync_release_notes.ps1` atualiza
`assets/release_notes.json`; com `-IncludeCurrentVersion`, inclui também o
arquivo `docs/releases/<versão>.md` quando essa versão ainda não foi publicada.
O antigo atalho `Prototipo-notas.bat` continua abrindo o menu normal por
compatibilidade, sem opções de layout experimentais.

## Publicação dos patches

Na próxima release, incrementar a versão normalmente e gerar o EXE completo.
Essa será a atualização de transição para quem ainda usa o atualizador antigo.
Nas releases seguintes, conservar os EXEs originais publicados e informar
quais versões instaladas terão um patch direto até a versão nova:

A geração normal já procura os dois EXEs de versões anteriores mais recentes
em `dist` e gera seus patches automaticamente. `-BaseExecutables` substitui
essa seleção quando for necessário atender outras versões. O empacotamento
desktop também permite `-WindowsBaseExecutables`.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/package_windows.ps1 -BaseExecutables dist/pesca-mortal-windows-v0.3.3.exe
```

Publicar tanto o EXE completo quanto todos os assets `.patch.gz` gerados. O
nome de cada patch inclui o SHA-256 completo do EXE de origem e a versão de
destino. Para vários EXEs de origem, usar o parâmetro array `-BaseExecutables`
numa sessão PowerShell. Isso permite saltar versões sem instalar cada uma.
Não renomear os patches. A API do GitHub deve fornecer seus digests.

O cliente prefere um patch compatível e menor que o EXE. Se nenhum corresponder
ao hash da instalação, baixa o EXE completo. O instalador verifica o hash do
download, o hash da base e o hash do EXE reconstruído antes de substituir o
jogo. Mantém o mesmo processo de backup/restauração e os saves existentes.
Após erro no patch, Tentar novamente usa o EXE completo nessa sessão.

O formato reutiliza blocos de 16 KiB e comprime os dados alterados com gzip.
Ele mantém o formato de distribuição em um único EXE. Não garante um tamanho
fixo: mudanças grandes ou deslocamentos podem aumentar o patch. O gerador
descarta patches maiores que o EXE completo.

## Validação

`scripts/test_windows_delta.ps1`: reconstrução, economia para alteração pequena,
base incorreta e arquivo truncado. `scripts/test_update_installer.ps1`: patches,
EXE, ZIP, reabertura e recuperação de falhas. `scripts/test_patch_notes.gd`:
histórico oficial, modo offline, falhas de consulta, layout, visibilidade da versão
e retorno ao menu; `-- --capture` salva prévias
em `.tools`. Essas capturas e os EXEs de validação não são assets de release.
