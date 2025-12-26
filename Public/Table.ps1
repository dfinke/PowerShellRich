
function New-RichTable {
    <#
    .SYNOPSIS
        Creates a new Rich Table object.
    .DESCRIPTION
        Initializes a table object that can be customized with columns and rows, and then rendered to the console.
    .PARAMETER Title
        An optional title for the table.
    .PARAMETER HeaderStyle
        The style for the table header. Defaults to "bold magenta".
    .PARAMETER BorderStyle
        The style for the table borders. Defaults to "white".
    .PARAMETER ShowHeader
        Whether to display the header row. Defaults to $true.
    .PARAMETER Border
        The border style: "rounded", "simple", or "none". Defaults to "rounded".
    .PARAMETER Columns
        Legacy support: A list of column headers.
    .PARAMETER Rows
        Legacy support: A list of rows (arrays of values).
    .EXAMPLE
        $table = New-RichTable -Title "Process List"
        $null = New-RichTableColumn -Table $table -Header "Name"
        $null = New-RichTableColumn -Table $table -Header "ID"
        Add-RichTableRow -Table $table -Values @("pwsh", 1234)
        $table | Write-Rich
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
    <#
    .SYNOPSIS
        Adds a column definition to a Rich Table.
    .DESCRIPTION
        Defines a column with header text, width, style, and justification.
    .PARAMETER Table
        The table object to add the column to.
    .PARAMETER Header
        The header text for the column.
    .PARAMETER Width
        An optional fixed width for the column.
    .PARAMETER Style
        The style for the column content.
    .PARAMETER Justify
        The text justification: "Left", "Right", or "Center". Defaults to "Left".
    #>
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
    <#
    .SYNOPSIS
        Adds a row of data to a Rich Table.
    .DESCRIPTION
        Appends a row of values to the specified table.
    .PARAMETER Table
        The table object to add the row to.
    .PARAMETER Values
        An array of values for the row.
    #>
    param(
        [Parameter(Mandatory = $true)]
        $Table,

        [Parameter(Mandatory = $true)]
        [array]$Values
    )

    $Table.Rows.Add($Values)
}

function Format-RichTable {
    <#
    .SYNOPSIS
        Renders a Rich Table to a string.
    .DESCRIPTION
        Calculates column widths and renders the table with borders and styles into a single string.
    .PARAMETER Table
        The table object to render.
    #>
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
