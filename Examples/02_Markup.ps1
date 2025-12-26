
Import-Module "$PSScriptRoot\..\PowerShellRich.psd1" -Force

Write-Rich "Rich supports [bold magenta]Markup[/]!"
Write-Rich "You can use [red]colors[/], [italic]styles[/], and [underline]more[/]."
Write-Rich "Even [yellow on blue]backgrounds[/] work in markup."
Write-Rich "Multiple tags: [bold]Bold[/] and [green]Green[/] and [italic]Italic[/]."
