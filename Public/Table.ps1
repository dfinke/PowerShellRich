
function New-RichTable {
    <#
    .SYNOPSIS
        Creates a new Rich Table object.
    #>
    param(
        [string]$Title,
        [string]$HeaderStyle = "bold magenta",
        [string]$BorderStyle = "white",
        [bool]$ShowHeader = $true,
        [string]$Border = "rounded", # rounded, simple, none
        
        # Legacy support for the old signature
        [string[]]$Columns,
        [array]$Rows
    )

    $table = [PSCustomObject]@{
        _Type       = "RichTable"
        Title       = $Title
        HeaderStyle = $HeaderStyle
        BorderStyle = $BorderStyle
        ShowHeader  = $ShowHeader
        Border      = $Border
        Columns     = [System.Collections.Generic.List[object]]::new()
        Rows        = [System.Collections.Generic.List[array]]::new()
    }

    # Handle legacy parameters
    if ($Columns) {
        foreach ($col in $Columns) {
            $null = New-RichTableColumn -Table $table -Header $col
        }
    }

    if ($Rows) {
        foreach ($row in $Rows) {
            $null = Add-RichTableRow -Table $table -Values $row
        }
    }

    return $table
}

function New-RichTableColumn {
    param(
        [Parameter(Mandatory = $true)]
        $Table,

        [string]$Header = "",
        [int]$Width = 0,
        [string]$Style = "",
        [string]$Justify = "Left"
    )

    $column = [PSCustomObject]@{
        Header  = $Header
        Width   = $Width
        Style   = $Style
        Justify = $Justify
    }

    $Table.Columns.Add($column)
    return $column
}

function Add-RichTableRow {
    param(
        [Parameter(Mandatory = $true)]
        $Table,

        [Parameter(Mandatory = $true)]
        [array]$Values
    )

    $Table.Rows.Add($Values)
}

function Format-RichTable {
    param(
        [Parameter(Mandatory = $true)]
        $Table
    )

    if ($Table.Columns.Count -eq 0) { return "" }

    $colCount = $Table.Columns.Count
    $widths = New-Object int[] $colCount

    # Calculate widths
    for ($i = 0; $i -lt $colCount; $i++) {
        $col = $Table.Columns[$i]
        $widths[$i] = [Math]::Max($col.Width, (Get-VisibleLength (Convert-RichMarkup -InputString $col.Header)))
    }

    foreach ($row in $Table.Rows) {
        for ($i = 0; $i -lt $colCount; $i++) {
            if ($i -lt $row.Count) {
                $len = Get-VisibleLength (Convert-RichMarkup -InputString ($row[$i].ToString()))
                if ($len -gt $widths[$i]) {
                    $widths[$i] = $len
                }
            }
        }
    }

    $output = New-Object System.Collections.Generic.List[string]

    if ($Table.Title) {
        $output.Add((Format-RichText -Text "  $($Table.Title)" -Style "bold underline"))
    }

    # Border characters
    $chars = @{
        top_left     = "┌"; top_mid = "┬"; top_right = "┐"
        mid_left     = "├"; mid_mid = "┼"; mid_right = "┤"
        bottom_left  = "└"; bottom_mid = "┴"; bottom_right = "┘"
        v            = "│"; h = "─"
    }

    if ($Table.Border -eq "simple") {
        $chars = @{
            top_left     = " "; top_mid = " "; top_right = " "
            mid_left     = " "; mid_mid = "─"; mid_right = " "
            bottom_left  = " "; bottom_mid = "─"; bottom_right = " "
            v            = " "; h = "─"
        }
    }
    elseif ($Table.Border -eq "none") {
        $chars = @{
            top_left     = ""; top_mid = ""; top_right = ""
            mid_left     = ""; mid_mid = ""; mid_right = ""
            bottom_left  = ""; bottom_mid = ""; bottom_right = ""
            v            = ""; h = ""
        }
    }

    # Top border
    if ($Table.Border -ne "none") {
        $top = $chars.top_left
        for ($i = 0; $i -lt $colCount; $i++) {
            $top += ($chars.h * ($widths[$i] + 2))
            if ($i -lt $colCount - 1) { $top += $chars.top_mid }
        }
        $top += $chars.top_right
        if ($top.Trim()) { $output.Add((Format-RichText -Text $top -Style $Table.BorderStyle)) }
    }

    # Header
    if ($Table.ShowHeader) {
        $headerRow = $chars.v
        for ($i = 0; $i -lt $colCount; $i++) {
            $col = $Table.Columns[$i]
            $val = Convert-RichMarkup -InputString $col.Header
            $padding = " " * ($widths[$i] - (Get-VisibleLength $val))
            $headerRow += " " + $val + $padding + " " + $chars.v
        }
        $output.Add((Format-RichText -Text $headerRow -Style $Table.HeaderStyle))

        # Separator
        if ($Table.Border -ne "none") {
            $sep = $chars.mid_left
            for ($i = 0; $i -lt $colCount; $i++) {
                $sep += ($chars.h * ($widths[$i] + 2))
                if ($i -lt $colCount - 1) { $sep += $chars.mid_mid }
            }
            $sep += $chars.mid_right
            $output.Add((Format-RichText -Text $sep -Style $Table.BorderStyle))
        }
    }

    # Rows
    foreach ($row in $Table.Rows) {
        $r = $chars.v
        for ($i = 0; $i -lt $colCount; $i++) {
            $col = $Table.Columns[$i]
            $val = if ($i -lt $row.Count) { Convert-RichMarkup -InputString ($row[$i].ToString()) } else { "" }
            
            if ($col.Style) {
                $val = Format-RichText -Text $val -Style $col.Style
            }

            $visibleLen = Get-VisibleLength $val
            $paddingTotal = $widths[$i] - $visibleLen
            
            if ($col.Justify -eq "Right") {
                $r += " " + (" " * $paddingTotal) + $val + " " + $chars.v
            } elseif ($col.Justify -eq "Center") {
                $leftPad = [int]($paddingTotal / 2)
                $rightPad = $paddingTotal - $leftPad
                $r += " " + (" " * $leftPad) + $val + (" " * $rightPad) + " " + $chars.v
            } else {
                $r += " " + $val + (" " * $paddingTotal) + " " + $chars.v
            }
        }
        $output.Add((Format-RichText -Text $r -Style $Table.BorderStyle))
    }

    # Bottom border
    if ($Table.Border -ne "none") {
        $bottom = $chars.bottom_left
        for ($i = 0; $i -lt $colCount; $i++) {
            $bottom += ($chars.h * ($widths[$i] + 2))
            if ($i -lt $colCount - 1) { $bottom += $chars.bottom_mid }
        }
        $bottom += $chars.bottom_right
        if ($bottom.Trim()) { $output.Add((Format-RichText -Text $bottom -Style $Table.BorderStyle)) }
    }

    return $output -join "`n"
}
