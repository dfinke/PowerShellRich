function New-RichLayout {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Name = "root",
        
        [Parameter(Mandatory = $false)]
        [int]$Ratio = 1,
        
        [Parameter(Mandatory = $false)]
        [int]$Size = $null,
        
        [Parameter(Mandatory = $false)]
        [PSObject]$Content = $null
    )

    $layout = [PSCustomObject]@{
        Name      = $Name
        Ratio     = $Ratio
        Size      = $Size
        Content   = $Content
        Children  = @()
        Direction = "Vertical" # Vertical (rows) or Horizontal (columns)
    }
    
    return $layout
}

function Split-RichLayout {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSObject]$Layout,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("Vertical", "Horizontal")]
        [string]$Direction,
        
        [Parameter(Mandatory = $true)]
        [string[]]$Names
    )

    $Layout.Direction = $Direction
    foreach ($name in $Names) {
        $child = New-RichLayout -Name $name
        $Layout.Children += $child
    }
}

function Update-RichLayout {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSObject]$Layout,
        
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $true)]
        [PSObject]$Content
    )

    if ($Layout.Name -eq $Name) {
        $Layout.Content = $Content
        return $true
    }

    foreach ($child in $Layout.Children) {
        if (Update-RichLayout -Layout $child -Name $Name -Content $Content) {
            return $true
        }
    }

    return $false
}

function Format-RichLayout {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSObject]$Layout,
        
        [Parameter(Mandatory = $false)]
        [int]$Width = $null,
        
        [Parameter(Mandatory = $false)]
        [int]$Height = $null
    )

    if ($null -eq $Width) { $Width = [Console]::WindowWidth }
    if ($null -eq $Height) { $Height = 20 } # Default height if not specified

    # Recursive rendering logic
    # This is complex because we need to return a list of strings (lines)
    
    if ($Layout.Children.Count -eq 0) {
        # Leaf node: render content
        if ($null -ne $Layout.Content) {
            $panel = New-RichPanel -Text $Layout.Content -Title $Layout.Name -Width $Width -Height $Height
            return $panel -split "`r?`n"
        } else {
            # Empty region with border
            $panel = New-RichPanel -Text "" -Title $Layout.Name -Width $Width -Height $Height
            return $panel -split "`r?`n"
        }
    }

    # Split space among children
    $lines = @()
    if ($Layout.Direction -eq "Vertical") {
        # Rows
        $totalRatio = 0
        foreach ($child in $Layout.Children) { $totalRatio += $child.Ratio }
        
        $remainingHeight = $Height
        for ($i = 0; $i -lt $Layout.Children.Count; $i++) {
            $child = $Layout.Children[$i]
            $childHeight = [int]($Height * ($child.Ratio / $totalRatio))
            if ($i -eq $Layout.Children.Count - 1) { $childHeight = $remainingHeight }
            $remainingHeight -= $childHeight
            
            if ($childHeight -gt 0) {
                $lines += Format-RichLayout -Layout $child -Width $Width -Height $childHeight
            }
        }
    } else {
        # Columns
        $totalRatio = 0
        foreach ($child in $Layout.Children) { $totalRatio += $child.Ratio }
        
        $childLines = @()
        $childWidths = @()
        $remainingWidth = $Width
        for ($i = 0; $i -lt $Layout.Children.Count; $i++) {
            $child = $Layout.Children[$i]
            $childWidth = [int]($Width * ($child.Ratio / $totalRatio))
            if ($i -eq $Layout.Children.Count - 1) { $childWidth = $remainingWidth }
            $remainingWidth -= $childWidth
            
            if ($childWidth -gt 0) {
                $childLines += ,(Format-RichLayout -Layout $child -Width $childWidth -Height $Height)
                $childWidths += $childWidth
            }
        }
        
        # Combine column lines side-by-side
        for ($y = 0; $y -lt $Height; $y++) {
            $line = ""
            for ($i = 0; $i -lt $childLines.Count; $i++) {
                $col = $childLines[$i]
                $w = $childWidths[$i]
                if ($y -lt $col.Count) {
                    $line += $col[$y]
                } else {
                    $line += " " * $w
                }
            }
            $lines += $line
        }
    }

    return $lines
}
