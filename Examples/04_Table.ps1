
Import-Module "$PSScriptRoot\..\PowerShellRich.psd1" -Force

$cols = @("ID", "Name", "Status", "Progress")
$rows = @(
    @("1", "Task A", "[green]Completed[/]", "100%"),
    @("2", "Task B", "[yellow]In Progress[/]", "45%"),
    @("3", "Task C", "[red]Failed[/]", "0%"),
    @("4", "Task D", "[blue]Pending[/]", "-")
)

$table = New-RichTable -Columns $cols -Rows $rows -Title "Project Status" -HeaderStyle "bold cyan" -BorderStyle "dim white"
Write-Rich $table
