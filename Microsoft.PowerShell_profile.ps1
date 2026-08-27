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

#region Aliases uteis
Set-Alias -Name ll -Value Get-ChildItem
function which ($command) { Get-Command $command | Select-Object -ExpandProperty Source }
function touch ($file) { New-Item -ItemType File -Force -Path $file | Out-Null }
#endregion
