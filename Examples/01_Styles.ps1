
Import-Module "$PSScriptRoot\..\PowerShellRich.psd1" -Force

Write-Host "--- Basic Colors ---"
"black", "red", "green", "yellow", "blue", "magenta", "cyan", "white" | ForEach-Object {
    Write-Rich "This is $_" -Style $_
}

Write-Host "`n--- Styles ---"
"bold", "dim", "italic", "underline", "blink", "reverse", "strike" | ForEach-Object {
    Write-Rich "This is $_" -Style $_
}

Write-Host "`n--- Backgrounds ---"
Write-Rich "Red on White" -Style "red on white"
Write-Rich "White on Blue" -Style "white on blue"
