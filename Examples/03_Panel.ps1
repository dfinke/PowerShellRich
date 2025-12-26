
Import-Module "$PSScriptRoot\..\PowerShellRich.psd1" -Force

# Simple Panel
$p1 = New-RichPanel -Text "Hello World"
Write-Rich $p1

# Panel with Title and Style
$p2 = New-RichPanel -Text "This is a [bold]styled[/] panel content." -Title "Important" -Style "magenta"
Write-Rich $p2

# Multi-line Panel
$content = @"
Line 1: [green]Success[/]
Line 2: [yellow]Warning[/]
Line 3: [red]Error[/]
"@
$p3 = New-RichPanel -Text $content -Title "Logs" -Style "cyan"
Write-Rich $p3
