# Oh My Posh — setup do terminal Windows

Configuração do meu terminal (tema Dracula em duas linhas, Nerd Font, Windows Terminal com esquema Cyberpunk Neon).

## Numa máquina nova

Sem clonar nada:

```powershell
irm https://raw.githubusercontent.com/Alzemiro/Oh-My-Posh/main/setup.ps1 | iex
```

Ou, se quiseres os ficheiros versionados na máquina (para editar o tema e fazer push):

```powershell
git clone https://github.com/Alzemiro/Oh-My-Posh.git
cd Oh-My-Posh
.\setup.ps1
```

Depois abre um terminal novo.

O script usa os ficheiros de config que estiverem ao lado dele; se não existirem — o caso do `irm` — descarrega-os do GitHub para `%TEMP%\omp-setup`.

## O que o `setup.ps1` faz

1. `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser` — sem isto o perfil não carrega
2. Instala o Oh My Posh via `winget` (salta se já existir)
3. Instala a **MesloLGS Nerd Font** a nível de utilizador, sem admin (salta se já existir)
4. Copia `config.json` para `~\.config\oh-my-posh\`
5. Copia o perfil para o Windows PowerShell 5.1 **e** para o PowerShell 7
6. Aplica fonte + esquema `Cyberpunk Neon` no Windows Terminal
7. Aplica a fonte no terminal integrado do VSCode

Os passos 6 e 7 fazem **merge** — os perfis e as restantes definições da máquina são preservados. Qualquer ficheiro sobrescrito fica com uma cópia `.bak` ao lado. Correr o script duas vezes é seguro.

```powershell
.\setup.ps1 -SelfTest   # valida o merge de JSON sem tocar em nada
```

## Ficheiros

| Ficheiro | Destino |
|---|---|
| `config.json` | `~\.config\oh-my-posh\config.json` |
| `Microsoft.PowerShell_profile.ps1` | `<Documentos>\{WindowsPowerShell,PowerShell}\` |
| `wt-scheme.json` | entrada em `schemes` do Windows Terminal |

Documentação dos segmentos e cores: `dev-setup\oh-my-posh.md`.
