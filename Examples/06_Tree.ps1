Import-Module "$PSScriptRoot\..\PowerShellRich.psd1" -Force

# Create a root tree
$root = New-RichTree -Label "[bold magenta]Rich Tree[/]"

# Add some branches
$renderables = Add-RichTree -Tree $root -Label "[bold cyan]Renderables[/]"
[void](Add-RichTree -Tree $renderables -Label "Panel")
[void](Add-RichTree -Tree $renderables -Label "Table")
[void](Add-RichTree -Tree $renderables -Label "Tree")

$styles = Add-RichTree -Tree $root -Label "[bold green]Styles[/]"
[void](Add-RichTree -Tree $styles -Label "Colors")
[void](Add-RichTree -Tree $styles -Label "Markup")

# Add a nested branch
$nested = Add-RichTree -Tree $renderables -Label "Nested"
[void](Add-RichTree -Tree $nested -Label "Deep 1")
[void](Add-RichTree -Tree $nested -Label "Deep 2")

# Output the tree
Format-RichTree -Tree $root | Write-Rich
