
function New-RichPanel {
    param(
        [Parameter(ValueFromPipeline = $true)]
        [string]$Text,
        [string]$Title,
        [string]$Style = "white",
        [string]$BoxStyle = "rounded",
        $Width,
        $Height
    )

    # Convert markup first so we can calculate visible length
    $formattedText = Convert-RichMarkup -InputString $Text
    $lines = $formattedText -split "`r?`n"
    
    if ($null -eq $Width) {
        $maxWidth = 0
        foreach ($line in $lines) {
            $len = Get-VisibleLength -Text $line
            if ($len -gt $maxWidth) { $maxWidth = $len }
        }
        if ($Title -and ($Title.Length + 4 -gt $maxWidth)) { $maxWidth = $Title.Length + 4 }
        $Width = $maxWidth + 4
    }

    if ($Width -lt 4) { $Width = 4 }
    if ($null -ne $Height -and $Height -lt 2) { $Height = 2 }

    $innerWidth = $Width - 4
    if ($innerWidth -lt 0) { $innerWidth = 0 }

    $top = "╭─"
    if ($Title) {
        $titleText = " $Title "
        if ($titleText.Length -gt $innerWidth) {
            $titleText = $titleText.Substring(0, $innerWidth)
        }
        $top += $titleText
        $top += "─" * ($Width - $titleText.Length - 4)
    }
    else {
        $top += "─" * ($Width - 4)
    }
    $top += "─╮"

    $output = New-Object System.Collections.Generic.List[string]
    $output.Add((Format-RichText -Text $top -Style $Style))

    $contentHeight = 0
    foreach ($line in $lines) {
        if ($null -ne $Height -and $contentHeight -ge ($Height - 2)) { break }
        
        $visibleLen = Get-VisibleLength -Text $line
        if ($visibleLen -gt $innerWidth) {
            # Truncate if too long
            # We should ideally strip ANSI, truncate, then re-apply or just use a helper
            # For now, let's just truncate the string and hope for the best
            if ($line.Length -gt $innerWidth) {
                $line = $line.Substring(0, $innerWidth)
            }
            $visibleLen = Get-VisibleLength -Text $line
        }
        
        $padding = " " * ($innerWidth - $visibleLen)
        $row = "│ " + $line + $padding + " │"
        $output.Add((Format-RichText -Text $row -Style $Style))
        $contentHeight++
    }

    # Fill remaining height if specified
    if ($null -ne $Height) {
        while ($output.Count -lt ($Height - 1)) {
            $padding = " " * $innerWidth
            $row = "│ " + $padding + " │"
            $output.Add((Format-RichText -Text $row -Style $Style))
        }
    }

    $bottomWidth = $Width - 2
    if ($bottomWidth -lt 0) { $bottomWidth = 0 }
    $bottom = "╰" + ("─" * $bottomWidth) + "╯"
    $output.Add((Format-RichText -Text $bottom -Style $Style))

    return $output -join "`n"
}
