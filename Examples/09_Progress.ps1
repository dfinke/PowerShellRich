Import-Module ".\PowerShellRich.psd1" -Force

Write-Rich "[bold cyan]Progress Bar Demo[/]"

Start-RichProgress -ScriptBlock {
    $task1 = Add-RichProgressTask -Description "Downloading" -Total 100
    $task2 = Add-RichProgressTask -Description "Processing" -Total 200
    $task3 = Add-RichProgressTask -Description "Uploading" -Total 50

    for ($i = 0; $i -le 100; $i += 5) {
        Update-RichProgress -Id $task1 -Completed $i
        if ($i -le 50) {
            Update-RichProgress -Id $task3 -Advance 5
        }
        Start-Sleep -Milliseconds 100
    }

    for ($i = 0; $i -le 200; $i += 10) {
        Update-RichProgress -Id $task2 -Completed $i
        Start-Sleep -Milliseconds 50
    }
}

Write-Rich "[bold green]All transfers complete![/]"
