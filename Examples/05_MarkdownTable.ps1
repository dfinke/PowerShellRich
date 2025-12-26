
Import-Module "$PSScriptRoot\..\PowerShellRich.psd1" -Force

$md = @"
| Feature | Status | Description |
|---------|--------|-------------|
| Colors  | [green]Done[/] | ANSI 16 colors supported |
| Markup  | [green]Done[/] | BBCode-like syntax |
| Panels  | [green]Done[/] | Boxed content |
| Tables  | [green]Done[/] | Auto-sizing grids |
| Markdown| [yellow]WIP[/]  | Basic table conversion |
"@

Write-Rich "Converting Markdown Table:"
$table = Convert-MarkdownTable -Markdown $md
Write-Rich $table
