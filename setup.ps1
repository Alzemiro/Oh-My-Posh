<#
.SYNOPSIS
    Replica a configuracao do terminal (Oh My Posh + Nerd Font + perfil + Windows Terminal + VSCode)
    numa maquina Windows nova.
.EXAMPLE
    .\setup.ps1
.EXAMPLE
    .\setup.ps1 -SelfTest   # valida o merge de JSON sem tocar em nada da maquina
#>
[CmdletBinding()]
param([switch]$SelfTest)

$ErrorActionPreference = 'Stop'

$FontFace   = 'MesloLGS Nerd Font'
$FontSize   = 11
$WtSettings = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
$VsCodeSettings = "$env:APPDATA\Code\User\settings.json"

function Write-Step($Message) { Write-Host "==> $Message" -ForegroundColor Cyan }
function Write-Skip($Message) { Write-Host "    (salta) $Message" -ForegroundColor DarkGray }

function Set-JsonProp($Object, $Name, $Value) {
    $Object | Add-Member -NotePropertyName $Name -NotePropertyValue $Value -Force
}

function Copy-Config($Source, $Destination) {
    $dir = Split-Path $Destination -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    if (Test-Path $Destination) { Copy-Item $Destination "$Destination.bak" -Force }
    Copy-Item $Source $Destination -Force
    Write-Host "    $Destination"
}

# Le, muta e reescreve um JSON preservando tudo o resto do ficheiro.
# ConvertFrom-Json do PS 5.1 rejeita comentarios/virgulas finais: nesse caso nao mexemos no ficheiro.
function Merge-JsonFile {
    param([string]$Path, [scriptblock]$Mutator)

    try { $json = Get-Content $Path -Raw -Encoding UTF8 | ConvertFrom-Json }
    catch { Write-Skip "$Path nao e JSON valido para o PowerShell (comentarios?) - edita a mao"; return }

    & $Mutator $json
    Copy-Item $Path "$Path.bak" -Force
    $json | ConvertTo-Json -Depth 32 | Set-Content $Path -Encoding utf8
    Write-Host "    $Path"
}

# --- mutators -----------------------------------------------------------------

function Get-WtMutator($Scheme) {
    {
        param($j)
        if (-not $j.profiles)          { Set-JsonProp $j 'profiles' ([pscustomobject]@{}) }
        if (-not $j.profiles.defaults) { Set-JsonProp $j.profiles 'defaults' ([pscustomobject]@{}) }
        Set-JsonProp $j.profiles.defaults 'font' ([pscustomobject]@{ face = $FontFace; size = $FontSize })
        Set-JsonProp $j.profiles.defaults 'colorScheme' $Scheme.name

        $schemes = @($j.schemes) | Where-Object { $_ }
        if ($schemes.name -notcontains $Scheme.name) { $schemes = @($schemes) + $Scheme }
        Set-JsonProp $j 'schemes' @($schemes)
    }.GetNewClosure()
}

$VsCodeMutator = {
    param($j)
    Set-JsonProp $j 'terminal.integrated.fontFamily' $FontFace
}

# --- self-test ----------------------------------------------------------------

if ($SelfTest) {
    $scheme = Get-Content "$PSScriptRoot\wt-scheme.json" -Raw -Encoding UTF8 | ConvertFrom-Json
    $mutator = Get-WtMutator $scheme
    $tmp = Join-Path $env:TEMP "wt-selftest-$PID.json"

    @'
{
  "defaultProfile": "{guid-a}",
  "profiles": { "list": [ { "name": "A" }, { "name": "B" } ] },
  "schemes": [ { "name": "Outro" } ]
}
'@ | Set-Content $tmp -Encoding utf8

    Merge-JsonFile -Path $tmp -Mutator $mutator | Out-Null
    Merge-JsonFile -Path $tmp -Mutator $mutator | Out-Null   # idempotencia

    $r = Get-Content $tmp -Raw -Encoding UTF8 | ConvertFrom-Json
    Remove-Item $tmp, "$tmp.bak" -Force -ErrorAction SilentlyContinue

    if ($r.defaultProfile -ne '{guid-a}')            { throw "SelfTest: chaves fora do nosso escopo foram perdidas" }
    if (@($r.profiles.list).Count -ne 2)             { throw "SelfTest: profiles.list foi destruido" }
    if (@($r.schemes).Count -ne 2)                   { throw "SelfTest: scheme duplicado ou em falta ($(@($r.schemes).Count))" }
    if ($r.schemes.name -notcontains 'Outro')        { throw "SelfTest: scheme pre-existente foi apagado" }
    if ($r.profiles.defaults.font.face -ne $FontFace){ throw "SelfTest: fonte nao aplicada" }
    if ($r.profiles.defaults.colorScheme -ne $scheme.name) { throw "SelfTest: colorScheme nao aplicado" }

    Write-Host "SelfTest OK" -ForegroundColor Green
    return
}

# --- setup --------------------------------------------------------------------

Write-Step 'Politica de execucao (necessaria para o perfil carregar)'
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

Write-Step 'Oh My Posh'
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    Write-Skip "ja instalado ($(oh-my-posh --version))"
} else {
    winget install --id JanDeDobbeleer.OhMyPosh --source winget --accept-package-agreements --accept-source-agreements
    # o winget so actualiza o PATH para sessoes novas; precisamos do executavel ja
    $env:PATH += ";$env:LOCALAPPDATA\Programs\oh-my-posh\bin"
}

Write-Step "Fonte ($FontFace)"
$fontKeys = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts',
            'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'
$hasFont = $fontKeys | Where-Object { Test-Path $_ } |
           ForEach-Object { (Get-ItemProperty $_).PSObject.Properties.Name } |
           Where-Object { $_ -like 'Meslo*Nerd*' }
if ($hasFont) { Write-Skip 'ja instalada' } else { oh-my-posh font install meslo }

Write-Step 'Tema'
Copy-Config "$PSScriptRoot\config.json" "$env:USERPROFILE\.config\oh-my-posh\config.json"

Write-Step 'Perfil PowerShell (5.1 e 7)'
$docs = [Environment]::GetFolderPath('MyDocuments')   # respeita a redireccao do OneDrive
foreach ($shell in 'WindowsPowerShell', 'PowerShell') {
    Copy-Config "$PSScriptRoot\Microsoft.PowerShell_profile.ps1" "$docs\$shell\Microsoft.PowerShell_profile.ps1"
}

Write-Step 'Windows Terminal'
if (Test-Path $WtSettings) {
    $scheme = Get-Content "$PSScriptRoot\wt-scheme.json" -Raw -Encoding UTF8 | ConvertFrom-Json
    Merge-JsonFile -Path $WtSettings -Mutator (Get-WtMutator $scheme)
} else {
    Write-Skip 'settings.json nao existe - abre o Windows Terminal uma vez e volta a correr'
}

Write-Step 'VSCode'
if (Test-Path $VsCodeSettings) {
    Merge-JsonFile -Path $VsCodeSettings -Mutator $VsCodeMutator
} else {
    Write-Skip 'nao instalado'
}

Write-Host ''
Write-Host 'Feito. Abre um terminal novo para ver o prompt.' -ForegroundColor Green
