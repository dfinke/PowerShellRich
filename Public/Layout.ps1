function New-RichLayout {
    <#
    .SYNOPSIS
        Creates a new Rich Layout object.
    .DESCRIPTION
        Initializes a layout container that can be split into rows or columns to create complex console UIs.
    .PARAMETER Name
        The name of the layout region.
    .PARAMETER Ratio
        The relative size ratio of this region compared to its siblings.
    .PARAMETER Size
        An optional fixed size for the region.
    .PARAMETER Content
        The content to display in this region (text or other Rich objects).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Name = "root",
        
        [Parameter(Mandatory = $false)]
        [int]$Ratio = 1,
        
        [Parameter(Mandatory = $false)]
        $Size,
        
        [Parameter(Mandatory = $false)]
        [PSObject]$Content = $null
    )

    $layout = [PSCustomObject]@{
        _Type     = "RichLayout"
        Name      = $Name
        Title     = $Name
        Ratio     = $Ratio
        Size      = $Size
        Content   = $Content
        Children  = @()
        Direction = "Vertical" # Vertical (rows) or Horizontal (columns)
    }
    
    return $layout
}

function Split-RichLayout {
    <#
    .SYNOPSIS
        Splits a layout region into multiple sub-regions.
    .DESCRIPTION
        Divides a layout region either vertically (into rows) or horizontally (into columns).
    .PARAMETER Layout
        The layout object to split.
    .PARAMETER Direction
        The direction of the split: "Vertical" (rows) or "Horizontal" (columns).
    .PARAMETER Names
        The names of the new sub-regions to create.
    #>
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
    <#
    .SYNOPSIS
        Updates the content of a named region in a layout.
    .DESCRIPTION
        Recursively searches for a region by name and updates its content.
    .PARAMETER Layout
        The root layout object.
    .PARAMETER Name
        The name of the region to update.
    .PARAMETER Content
        The new content for the region.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSObject]$Layout,
        
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $false)]
        [PSObject]$Content,

        [Parameter(Mandatory = $false)]
        [string]$Title
    )

    if ($Layout.Name -eq $Name) {
        if ($PSBoundParameters.ContainsKey('Content')) {
            $Layout.Content = $Content
        }
        if ($PSBoundParameters.ContainsKey('Title')) {
            $Layout.Title = $Title
        }
        return $true
    }

    foreach ($child in $Layout.Children) {
        $updateParams = @{
            Layout = $child
            Name   = $Name
        }
        if ($PSBoundParameters.ContainsKey('Content')) { $updateParams.Content = $Content }
        if ($PSBoundParameters.ContainsKey('Title')) { $updateParams.Title = $Title }

        if (Update-RichLayout @updateParams) {
            return $true
        }
    }

    return $false
}

function Format-RichLayout {
    <#
    .SYNOPSIS
        Renders a layout to a list of strings.
    .DESCRIPTION
        Calculates the dimensions of all regions and renders them into a list of strings that can be printed to the console.
    .PARAMETER Layout
        The layout object to render.
    .PARAMETER Width
        The total width for rendering. Defaults to the console window width.
    .PARAMETER Height
        The total height for rendering. Defaults to 20.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSObject]$Layout,
        
        [Parameter(Mandatory = $false)]
        $Width,
        
        [Parameter(Mandatory = $false)]
        $Height
    )

    if ($null -eq $Width) { $Width = [Console]::WindowWidth }
    if ($null -eq $Height) { $Height = 20 } # Default height if not specified

    # Recursive rendering logic
    # This is complex because we need to return a list of strings (lines)
    
    if ($Layout.Children.Count -eq 0) {
        # Leaf node: render content
        if ($null -ne $Layout.Content) {
            $panel = New-RichPanel -Text $Layout.Content -Title $Layout.Title -Width $Width -Height $Height
            return $panel -split "`r?`n"
        }
        else {
            # Empty region with border
            $panel = New-RichPanel -Text "" -Title $Layout.Title -Width $Width -Height $Height
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
            $childHeight = [int][Math]::Round($Height * ($child.Ratio / $totalRatio), [MidpointRounding]::AwayFromZero)
            if ($i -eq $Layout.Children.Count - 1) { $childHeight = $remainingHeight }
            $remainingHeight -= $childHeight
            
            if ($childHeight -gt 0) {
                $lines += Format-RichLayout -Layout $child -Width $Width -Height $childHeight
            }
        }
    }
    else {
        # Columns
        $totalRatio = 0
        foreach ($child in $Layout.Children) { $totalRatio += $child.Ratio }
        
        $childLines = @()
        $childWidths = @()
        $remainingWidth = $Width
        for ($i = 0; $i -lt $Layout.Children.Count; $i++) {
            $child = $Layout.Children[$i]
            $childWidth = [int][Math]::Round($Width * ($child.Ratio / $totalRatio), [MidpointRounding]::AwayFromZero)
            if ($i -eq $Layout.Children.Count - 1) { $childWidth = $remainingWidth }
            $remainingWidth -= $childWidth
            
            if ($childWidth -gt 0) {
                $childLines += , (Format-RichLayout -Layout $child -Width $childWidth -Height $Height)
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
                }
                else {
                    $line += " " * $w
                }
            }
            $lines += $line
        }
    }

    return $lines
}
