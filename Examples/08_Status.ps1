Import-Module "$PSScriptRoot\..\PowerShellRich.psd1" -Force

Write-Rich "[bold magenta]Status Spinner Demo[/]"

Start-RichStatus -Status "Downloading data..." -SpinnerName "dots" -ScriptBlock {
    Start-Sleep -Seconds 2
    Write-Rich "[green]Step 1 complete[/]"
    Start-Sleep -Seconds 1
}

Start-RichStatus -Status "Processing files..." -SpinnerName "moon" -SpinnerStyle "yellow" -ScriptBlock {
    Start-Sleep -Seconds 3
    Write-Rich "[green]Step 2 complete[/]"
}

Start-RichStatus -Status "Finalizing..." -SpinnerName "bouncingBall" -SpinnerStyle "bold blue" -ScriptBlock {
    Start-Sleep -Seconds 2
}

Write-Rich "[bold green]All tasks finished![/]"
