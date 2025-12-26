
$ESC = [char]27

$ANSI_STYLES = @{
    "reset"     = "0"
    "bold"      = "1"
    "dim"       = "2"
    "italic"    = "3"
    "underline" = "4"
    "blink"     = "5"
    "reverse"   = "7"
    "hidden"    = "8"
    "strike"    = "9"
}

$ANSI_COLORS = @{
    "black"   = "30"
    "red"     = "31"
    "green"   = "32"
    "yellow"  = "33"
    "blue"    = "34"
    "magenta" = "35"
    "cyan"    = "36"
    "white"   = "37"
    "default" = "39"
}

$ANSI_BG_COLORS = @{
    "black"   = "40"
    "red"     = "41"
    "green"   = "42"
    "yellow"  = "43"
    "blue"    = "44"
    "magenta" = "45"
    "cyan"    = "46"
    "white"   = "47"
    "default" = "49"
}

function Get-AnsiCode {
    param(
        [string]$Style
    )

    $codes = New-Object System.Collections.Generic.List[string]
    $parts = $Style -split " "

    $isBackground = $false
    foreach ($part in $parts) {
        if ($part -eq "on") {
            $isBackground = $true
            continue
        }

        if ($ANSI_STYLES.ContainsKey($part)) {
            $codes.Add($ANSI_STYLES[$part])
        }
        elseif ($isBackground -and $ANSI_BG_COLORS.ContainsKey($part)) {
            $codes.Add($ANSI_BG_COLORS[$part])
        }
        elseif (-not $isBackground -and $ANSI_COLORS.ContainsKey($part)) {
            $codes.Add($ANSI_COLORS[$part])
        }
    }

    if ($codes.Count -gt 0) {
        return "$ESC[" + ($codes -join ";") + "m"
    }
    return ""
}

function Format-RichText {
    param(
        [string]$Text,
        [string]$Style
    )

    $ansi = Get-AnsiCode -Style $Style
    if ($ansi) {
        return "$ansi$Text$ESC[0m"
    }
    return $Text
}

function Get-VisibleLength {
    param(
        [string]$Text
    )

    if (-not $Text) { return 0 }
    # Remove ANSI escape sequences
    $plain = $Text -replace "\x1b\[[0-9;]*m", ""
    return $plain.Length
}
