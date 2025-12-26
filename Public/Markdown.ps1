
function Convert-MarkdownTable {
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$Markdown
    )

    $lines = $Markdown -split "`r?`n" | Where-Object { $_ -match "\|" }
    if ($lines.Count -lt 3) { return "" }

    # Extract headers from the first line
    $headerLine = $lines[0].Trim().Trim('|')
    $columns = $headerLine -split "\|" | ForEach-Object { $_.Trim() }

    # Check for separator line (second line)
    $separatorLine = $lines[1].Trim().Trim('|')
    if ($separatorLine -notmatch "[-:]+") {
        return "" # Not a valid markdown table
    }

    # Extract rows from the rest
    $rows = New-Object System.Collections.Generic.List[array]
    for ($i = 2; $i -lt $lines.Count; $i++) {
        $rowLine = $lines[$i].Trim().Trim('|')
        $rowData = $rowLine -split "\|" | ForEach-Object { $_.Trim() }
        
        # Ensure row has same number of columns as header
        $rowArray = New-Object string[] $columns.Count
        for ($j = 0; $j -lt $columns.Count; $j++) {
            if ($j -lt $rowData.Count) {
                $rowArray[$j] = $rowData[$j]
            }
            else {
                $rowArray[$j] = ""
            }
        }
        $rows.Add($rowArray)
    }

    return New-RichTable -Columns $columns -Rows $rows.ToArray()
}
