function New-RichProgressBar {
    <#
    .SYNOPSIS
        Creates a styled progress bar string.
    .DESCRIPTION
        Generates a string representing a progress bar based on a percentage.
    .PARAMETER Percentage
        The completion percentage (0-100).
    .PARAMETER Width
        The width of the progress bar in characters. Defaults to 40.
    .PARAMETER CompletedStyle
        The style for the completed portion of the bar. Defaults to "bold green".
    .PARAMETER RemainingStyle
        The style for the remaining portion of the bar. Defaults to "white".
    #>
    param(
        [double]$Percentage,
        [int]$Width = 40,
        [string]$CompletedStyle = "bold green",
        [string]$RemainingStyle = "white"
    )

    $completedWidth = [int]($Width * ($Percentage / 100.0))
    if ($completedWidth -gt $Width) { $completedWidth = $Width }
    $remainingWidth = $Width - $completedWidth

    $completed = "━" * $completedWidth
    $remaining = "━" * $remainingWidth

    $styledCompleted = Format-RichText -Text $completed -Style $CompletedStyle
    $styledRemaining = Format-RichText -Text $remaining -Style $RemainingStyle

    return "$styledCompleted$styledRemaining"
}

function Start-RichProgress {
    <#
    .SYNOPSIS
        Runs a script block with live progress bars.
    .DESCRIPTION
        Executes a script block and provides a background thread to render live progress bars for tasks added via Add-RichProgressTask.
    .PARAMETER ScriptBlock
        The script block to execute.
    .PARAMETER RefreshRate
        The refresh rate for the progress display in milliseconds. Defaults to 10.
    .EXAMPLE
        Start-RichProgress {
            $id = Add-RichProgressTask -Description "Downloading" -Total 100
            for ($i = 0; $i -le 100; $i += 10) {
                Update-RichProgress -Id $id -Completed $i
                Start-Sleep -Milliseconds 200
            }
        }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,
        
        [Parameter(Mandatory = $false)]
        [int]$RefreshRate = 10
    )

    # Progress state
    $script:RichProgressTasks = @{}
    $script:RichProgressCounter = 0

    function global:Add-RichProgressTask {
        <#
        .SYNOPSIS
            Adds a new task to the live progress display.
        .DESCRIPTION
            Creates a task with a description and total value, returning a task ID for updates.
        .PARAMETER Description
            The description of the task.
        .PARAMETER Total
            The total value representing 100% completion. Defaults to 100.
        .PARAMETER Completed
            The initial completed value. Defaults to 0.
        #>
        param(
            [string]$Description,
            [double]$Total = 100,
            [double]$Completed = 0
        )
        $id = $script:RichProgressCounter++
        $script:RichProgressTasks[$id] = @{
            Description = $Description
            Total       = $Total
            Completed   = $Completed
            StartTime   = [DateTime]::Now
        }
        return $id
    }

    function global:Update-RichProgress {
        <#
        .SYNOPSIS
            Updates the progress of a task.
        .DESCRIPTION
            Updates a task's completion status by either advancing the current value or setting it to a specific value.
        .PARAMETER Id
            The ID of the task to update.
        .PARAMETER Advance
            The amount to add to the current completed value.
        .PARAMETER Completed
            The new absolute completed value. If specified, Advance is ignored.
        #>
        param(
            [int]$Id,
            [double]$Advance = 0,
            [double]$Completed = -1
        )
        if ($script:RichProgressTasks.ContainsKey($Id)) {
            if ($Completed -ge 0) {
                $script:RichProgressTasks[$Id].Completed = $Completed
            }
            else {
                $script:RichProgressTasks[$Id].Completed += $Advance
            }
        }
    }

    # Background thread for rendering
    $runspace = [runspacefactory]::CreateRunspace()
    $runspace.Open()
    
    # We need to share the tasks hashtable. In PowerShell, we can use a synchronized hashtable.
    $syncTasks = [hashtable]::Synchronized($script:RichProgressTasks)
    
    $powershell = [powershell]::Create().AddScript({
            param($tasks)
            [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
            [Console]::Write("$([char]27)[?25l") # Hide cursor

            try {
                while ($true) {
                    $output = ""
                    $taskIds = $tasks.Keys | Sort-Object
                
                    if ($taskIds.Count -gt 0) {
                        foreach ($id in $taskIds) {
                            $task = $tasks[$id]
                            $percent = ($task.Completed / $task.Total) * 100
                            if ($percent -gt 100) { $percent = 100 }
                        
                            # Simple bar construction (avoiding function calls for speed/scope)
                            $width = 30
                            $done = [int]($width * ($percent / 100.0))
                            $rem = $width - $done
                            $bar = "$([char]27)[32m" + ("━" * $done) + "$([char]27)[0m" + ("━" * $rem)
                        
                            $desc = $task.Description.PadRight(20).Substring(0, 20)
                            $output += "`r$([char]27)[K$desc $bar $([math]::Round($percent, 1))%`n"
                        }
                    
                        # Move cursor back up for next refresh
                        $up = "$([char]27)[" + $taskIds.Count + "A"
                        [Console]::Write("`r$output$up")
                    }
                
                    [System.Threading.Thread]::Sleep(100)
                }
            }
            catch {}
            finally {
                [Console]::Write("$([char]27)[?25h") # Show cursor
            }
        }).AddArgument($syncTasks)

    $powershell.Runspace = $runspace
    $handle = $powershell.BeginInvoke()

    try {
        &$ScriptBlock
    }
    finally {
        $powershell.Stop()
        $runspace.Close()
        $powershell.Dispose()
        $runspace.Dispose()
        
        # Move cursor past the progress bars
        $count = $script:RichProgressTasks.Count
        for ($i = 0; $i -lt $count; $i++) { Write-Host "" }
    }
}
