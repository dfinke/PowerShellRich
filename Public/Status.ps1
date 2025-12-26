$SPINNERS = @{
    "dots"         = @{
        "interval" = 80
        "frames"   = @("⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏")
    }
    "dots2"        = @{
        "interval" = 80
        "frames"   = @("⣾", "⣽", "⣻", "⢿", "⡿", "⣟", "⣯", "⣷")
    }
    "line"         = @{
        "interval" = 130
        "frames"   = @("-", "\", "|", "/")
    }
    "arc"          = @{
        "interval" = 100
        "frames"   = @("◜", "◠", "◝", "◞", "◡", "◟")
    }
    "moon"         = @{
        "interval" = 80
        "frames"   = @("🌑", "🌒", "🌓", "🌔", "🌕", "🌖", "🌗", "🌘")
    }
    "bouncingBall" = @{
        "interval" = 80
        "frames"   = @("( ●    )", "(  ●   )", "(   ●  )", "(    ● )", "(     ●)", "(    ● )", "(   ●  )", "(  ●   )")
    }
}

function New-RichSpinner {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Name = "dots",

        [Parameter(Mandatory = $false)]
        [string]$Text = "",

        [Parameter(Mandatory = $false)]
        [string]$Style = "cyan",

        [Parameter(Mandatory = $false)]
        [double]$Speed = 1.0
    )

    if (-not $SPINNERS.ContainsKey($Name)) {
        Write-Error "No spinner called '$Name'"
        return $null
    }

    $spinnerDef = $SPINNERS[$Name]
    return @{
        Name      = $Name
        Frames    = $spinnerDef.frames
        Interval  = $spinnerDef.interval
        Text      = $Text
        Style     = $Style
        Speed     = $Speed
        StartTime = [DateTime]::Now
    }
}

function Start-RichStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Status,

        [Parameter(Mandatory = $false)]
        [string]$SpinnerName = "dots",

        [Parameter(Mandatory = $false)]
        [string]$SpinnerStyle = "bold cyan",

        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock
    )

    $spinner = New-RichSpinner -Name $SpinnerName -Text $Status -Style $SpinnerStyle
    
    # We'll use a simple loop with a timeout for the scriptblock if possible,
    # but PowerShell doesn't easily support "running a scriptblock and updating UI" 
    # without threads or jobs.
    
    # For this port, we'll implement a "Live" update approach using a background thread
    # to handle the spinner animation while the main thread runs the scriptblock.

    $runspace = [runspacefactory]::CreateRunspace()
    $runspace.Open()
    
    $powershell = [powershell]::Create().AddScript({
            param($spinner, $status, $modulePath)
        
            # Ensure UTF8 output for Unicode spinners
            [Console]::OutputEncoding = [System.Text.Encoding]::UTF8

            # Import the module components needed for styling
            # We'll just use raw ANSI for simplicity in the thread to avoid complex imports
            function Get-SimpleAnsi {
                param($style)
                $esc = [char]27
                if ($style -match "bold") { $res += "$esc[1m" }
                if ($style -match "cyan") { $res += "$esc[36m" }
                if ($style -match "green") { $res += "$esc[32m" }
                if ($style -match "magenta") { $res += "$esc[35m" }
                if ($style -match "red") { $res += "$esc[31m" }
                if ($style -match "yellow") { $res += "$esc[33m" }
                if ($style -match "blue") { $res += "$esc[34m" }
                return $res
            }

            $frames = $spinner.Frames
            $styleCode = Get-SimpleAnsi -style $spinner.Style
            $reset = "$([char]27)[0m"
            $i = 0
        
            # Hide cursor
            [Console]::Write("$([char]27)[?25l")
        
            try {
                while ($true) {
                    $frame = $frames[$i % $frames.Count]
                    # Simple status rendering (no markup support in thread for now to keep it fast)
                    $cleanStatus = $status -replace "\[.*?\]", "" 
                
                    [Console]::Write("`r$([char]27)[K$styleCode$frame$reset $cleanStatus")
                
                    $i++
                    [System.Threading.Thread]::Sleep([int]($spinner.Interval / $spinner.Speed))
                }
            }
            catch {}
            finally {
                [Console]::Write("`r$([char]27)[K$([char]27)[?25h")
            }
        }).AddArgument($spinner).AddArgument($Status).AddArgument($PSScriptRoot)
    
    $powershell.Runspace = $runspace
    $handle = $powershell.BeginInvoke()

    try {
        # Run the actual work in the main thread
        $result = &$ScriptBlock
        return $result
    }
    finally {
        $powershell.Stop()
        $runspace.Close()
        $powershell.Dispose()
        $runspace.Dispose()
        # Ensure cursor is back and line is clean
        Write-Host -NoNewline "`r$([char]27)[K$([char]27)[?25h"
    }
}
