# Distribuição desktop

A geração de arquivos e a publicação são etapas separadas. Commits podem
ser reunidos normalmente; publicar uma release somente quando solicitado.
Os scripts de exportação não comitam, não enviam arquivos e não criam releases.

```powershell
powershell -NoProfile -File scripts/package_desktop.ps1
```

| Plataforma | Arquivo gerado em `dist/` | Como abrir |
| --- | --- | --- |
| Windows x86_64 | `pesca-mortal-windows-v0.2.1.exe` | Executar diretamente |
| macOS Apple Silicon (M1 e posteriores) | `pesca-mortal-macos-arm64-v0.2.1.zip` | Extrair o `.app` e abrir |
| Linux x86_64 (Intel/AMD 64 bits) | `pesca-mortal-linux-v0.2.1.x86_64` | Dar permissão de execução e executar |

O Windows e Linux usam PCK embutido: dados e recursos do jogo acompanham o
executável. No Linux, depois de baixar:

```sh
chmod +x pesca-mortal-linux-v0.2.1.x86_64
./pesca-mortal-linux-v0.2.1.x86_64
```

O Linux não usa `.dmg`: esse é um formato de imagem de disco do macOS.
O arquivo Linux é um executável ELF portátil, não um pacote `.deb`/`.rpm`
nem um AppImage. Não instala atalhos ou dependências no sistema.

Os nomes acima são exemplos para a próxima versão. Os scripts leem
`application/config/version` de `project.godot` e inserem esse valor nos
nomes de todas as plataformas automaticamente. Arquivos antigos em `dist/`
não são removidos nem substituídos pelos arquivos de uma nova versão.

No Mac, o ZIP conserva a estrutura e as permissões do `.app` exportado
pelo Godot no Windows. A exportação atual é ARM64, com assinatura ad-hoc
e sem notarização Apple. Não atende Macs Intel e ainda precisa ser testada
num Mac. Um DMG exige exportação no macOS; assinatura Developer ID e
notarização podem ser configuradas posteriormente.

A atualização automática implementada é para Windows. Mac e Linux ainda
oferecem download manual da release e jogar offline. Preparar os binários
dessas plataformas não habilita a substituição automática nesses sistemas.

Para uma plataforma só, usar `-Platforms macOS` ou `-Platforms Linux`.
Para gerar também o ZIP de transição aceito por clientes Windows 0.1.2,
usar `-LegacyWindowsZip`. Esse ZIP não é gerado por padrão.

Quando uma nova release for solicitada, atualizar a versão do jogo e do
exportador Mac, gerar e verificar os arquivos, e anexar os artefatos à
mesma release no GitHub. Não substituir a release antiga a cada commit.

Referências: [Godot — exportação macOS](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_macos.html),
[Godot — exportação Linux](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_linux.html).
