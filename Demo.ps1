Import-Module ".\PowerShellRich.psd1" -Force

# 1. Header
Write-Rich "[bold yellow]PowerShell Rich Port Demo[/]"
Write-Rich "[italic white]A port of the Python 'rich' library to PowerShell[/]"
Write-Host ""

# 2. Panels and Markup
Write-Rich "[bold cyan]1. Panels and Markup[/]"
$p = New-RichPanel -Text "This is a panel with [bold green]Rich Markup[/].`nIt supports [italic]italics[/], [underline]underline[/], and [bold magenta]colors[/]." -Title "Markup Demo" -Style "cyan"
Write-Host $p
Write-Host ""

# 3. Tables
Write-Rich "[bold cyan]2. Tables[/]"
$table = New-RichTable -Title "Star Wars Movies" -Style "yellow"
$null = New-RichTableColumn -Table $table -Header "Title" -Style "bold cyan"
$null = New-RichTableColumn -Table $table -Header "Year" -Justify "Right"
$null = Add-RichTableRow -Table $table -Values "A New Hope", "1977"
$null = Add-RichTableRow -Table $table -Values "The Empire Strikes Back", "1980"
$null = Add-RichTableRow -Table $table -Values "Return of the Jedi", "1983"
Write-Host (Format-RichTable -Table $table)
Write-Host ""

# 4. Trees
Write-Rich "[bold cyan]3. Trees[/]"
$tree = New-RichTree -Label "[bold green]Project Root[/]"
$src = Add-RichTree -Tree $tree -Label "src"
$null = Add-RichTree -Tree $src -Label "Main.ps1"
$null = Add-RichTree -Tree $src -Label "Utils.ps1"
$docs = Add-RichTree -Tree $tree -Label "docs"
$null = Add-RichTree -Tree $docs -Label "README.md"
Write-Host ((Format-RichTree -Tree $tree) -join "`n")
Write-Host ""

# 5. Columns
Write-Rich "[bold cyan]4. Columns[/]"
$fruits = "Apple", "Banana", "Cherry", "Date", "Elderberry", "Fig", "Grape"
$styledFruits = $fruits | ForEach-Object { Format-RichText -Text $_ -Style "bold green" }
Write-Host (New-RichColumns -Items $styledFruits -Width 60)
Write-Host ""

# 6. Progress and Status
Write-Rich "[bold cyan]5. Status and Progress[/]"
Start-RichStatus -Status "Initializing demo..." -SpinnerName "dots" -ScriptBlock {
    Start-Sleep -Seconds 1
}

Start-RichProgress -ScriptBlock {
    $t = Add-RichProgressTask -Description "Processing" -Total 100
    for ($i = 0; $i -le 100; $i += 20) {
        Update-RichProgress -Id $t -Completed $i
        Start-Sleep -Milliseconds 200
    }
}

Write-Rich "[bold green]Demo Complete![/]"
