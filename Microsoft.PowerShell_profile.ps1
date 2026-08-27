#region Oh My Posh
$env:POSH_GIT_ENABLED = $true
oh-my-posh init pwsh --config "$env:USERPROFILE\.config\oh-my-posh\config.json" | Invoke-Expression
#endregion

#region PSReadLine
if (Get-Module -ListAvailable -Name PSReadLine) {
    Import-Module PSReadLine
    Set-PSReadLineOption -EditMode Windows
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
    Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
    # PredictionSource e PredictionViewStyle requerem PSReadLine >= 2.2
    $psrlVersion = (Get-Module PSReadLine).Version
    if ($psrlVersion -ge [Version]"2.2.0") {
        Set-PSReadLineOption -PredictionSource History
        Set-PSReadLineOption -PredictionViewStyle ListView
    }
}
#endregion

#region Java
# Troca a versao do JDK na sessao actual: Use-Java 21
function Use-Java($Version) {
    $jdk = Get-ChildItem 'C:\Program Files\Eclipse Adoptium' -Directory -Filter "jdk-$Version*" -ErrorAction SilentlyContinue |
           Sort-Object Name -Descending | Select-Object -First 1
    if (-not $jdk) { Write-Warning "JDK $Version nao encontrado em C:\Program Files\Eclipse Adoptium"; return }
    $env:JAVA_HOME = $jdk.FullName
    # tira do PATH o JDK anterior, senao acumulam-se e o primeiro e que ganha
    $env:PATH = "$env:JAVA_HOME\bin;" + (($env:PATH -split ';' | Where-Object { $_ -notlike '*Eclipse Adoptium*' }) -join ';')
    java -version
}
#endregion

#region Aliases uteis
Set-Alias -Name ll -Value Get-ChildItem
function which ($command) { Get-Command $command | Select-Object -ExpandProperty Source }
function touch ($file) { New-Item -ItemType File -Force -Path $file | Out-Null }
#endregion
