Import-Module "$PSScriptRoot\..\PowerShellRich.psd1" -Force

$items = @(
    "[bold red]Apple[/]", "[bold green]Banana[/]", "[bold blue]Cherry[/]",
    "[bold yellow]Date[/]", "[bold magenta]Elderberry[/]", "[bold cyan]Fig[/]",
    "[bold white]Grape[/]", "[bold dim]Honeydew[/]", "[bold italic]Kiwi[/]",
    "Lemon", "Mango", "Nectarine", "Orange", "Papaya", "Quince", "Raspberry",
    "Strawberry", "Tangerine", "Ugli Fruit", "Watermelon"
)

Write-Rich "[bold underline]Fruit Columns[/]"
New-RichColumns -Items $items -Width 60 | Write-Rich
