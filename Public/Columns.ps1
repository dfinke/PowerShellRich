function New-RichColumns {
    <#
    .SYNOPSIS
        Arranges a list of items into columns.
    .PARAMETER Items
        The list of items to display.
    .PARAMETER Width
        The total width to use. Defaults to 80.
    .PARAMETER Padding
        The padding between columns. Defaults to 2.
    #>
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string[]]$Items,

        [int]$Width = 80,

        [int]$Padding = 2
    )

    if ($Items.Count -eq 0) { return "" }

    # Calculate max width of items
    $maxWidth = 0
    foreach ($item in $Items) {
        $len = Get-VisibleLength (Convert-RichMarkup $item)
        if ($len -gt $maxWidth) { $maxWidth = $len }
    }

    # Calculate how many columns fit
    $columnWidth = $maxWidth + $Padding
    $columnCount = [Math]::Floor($Width / $columnWidth)
    if ($columnCount -lt 1) { $columnCount = 1 }

    # Create a grid table
    $table = New-RichTable -ShowHeader:$false -Border "none"
    
    # Add columns
    for ($i = 0; $i -lt $columnCount; $i++) {
        $null = New-RichTableColumn -Table $table -Width $maxWidth
    }

    # Add rows
    $rowCount = [Math]::Ceiling($Items.Count / $columnCount)
    for ($r = 0; $r -lt $rowCount; $r++) {
        $row = New-Object string[] $columnCount
        for ($c = 0; $c -lt $columnCount; $c++) {
            $index = ($r * $columnCount) + $c
            if ($index -lt $Items.Count) {
                $row[$c] = $Items[$index]
            }
            else {
                $row[$c] = ""
            }
        }
        $null = Add-RichTableRow -Table $table -Values $row
    }

    return Format-RichTable -Table $table
}
