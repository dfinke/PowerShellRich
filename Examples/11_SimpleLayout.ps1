Import-Module ".\PowerShellRich.psd1" -Force

$layout = New-RichLayout -Name "root"
Split-RichLayout -Layout $layout -Direction "Horizontal" -Names "left", "right"

Update-RichLayout -Layout $layout -Name "left" -Content "Left Side"
Update-RichLayout -Layout $layout -Name "right" -Content "Right Side"

$rendered = Format-RichLayout -Layout $layout -Width 40 -Height 5
$rendered | ForEach-Object { Write-Host $_ }
