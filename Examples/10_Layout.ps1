Import-Module ".\PowerShellRich.psd1" -Force

$layout = New-RichLayout -Name "root"
Split-RichLayout -Layout $layout -Direction "Vertical" -Names "header", "body", "footer"

# Update ratios
$layout.Children[0].Ratio = 1 # header
$layout.Children[1].Ratio = 4 # body
$layout.Children[2].Ratio = 1 # footer

# Split body into sidebar and content
Split-RichLayout -Layout $layout.Children[1] -Direction "Horizontal" -Names "sidebar", "content"
$layout.Children[1].Children[0].Ratio = 1 # sidebar
$layout.Children[1].Children[1].Ratio = 3 # content

# Add some content
Update-RichLayout -Layout $layout -Name "header" -Content "[bold yellow]My Rich Dashboard[/]"
Update-RichLayout -Layout $layout -Name "sidebar" -Content "Menu:`n- Home`n- Stats`n- Settings"
Update-RichLayout -Layout $layout -Name "content" -Content "Welcome to the [bold green]Rich[/] layout demo!`nThis layout is split into rows and columns."
Update-RichLayout -Layout $layout -Name "footer" -Content "[italic]Press Ctrl+C to exit[/]"

$rendered = Format-RichLayout -Layout $layout -Width 80 -Height 15
$rendered | ForEach-Object { Write-Host $_ }
