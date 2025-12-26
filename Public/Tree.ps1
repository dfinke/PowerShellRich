function New-RichTree {
    <#
    .SYNOPSIS
        Creates a new Rich Tree object.
    .DESCRIPTION
        Initializes a tree structure for displaying hierarchical data in the console.
    .PARAMETER Label
        The label for the root of the tree. Can include Rich markup.
    .PARAMETER GuideStyle
        The style for the guide lines (e.g., "dim", "white").
    .EXAMPLE
        $tree = New-RichTree -Label "[bold blue]Root[/]"
        Add-RichTree -Tree $tree -Label "Child 1"
        $tree | Write-Rich
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Label,

        [string]$GuideStyle = "dim"
    )

    $tree = [PSCustomObject]@{
        _Type      = "RichTree"
        Label      = $Label
        GuideStyle = $GuideStyle
        Children   = [System.Collections.Generic.List[object]]::new()
    }

    return $tree
}

function Add-RichTree {
    <#
    .SYNOPSIS
        Adds a child node to a Rich Tree.
    .DESCRIPTION
        Creates a new child node and adds it to the specified parent tree or node.
    .PARAMETER Tree
        The parent tree or node object.
    .PARAMETER Label
        The label for the child node. Can include Rich markup.
    #>
    param(
        [Parameter(Mandatory = $true)]
        $Tree,

        [Parameter(Mandatory = $true)]
        [string]$Label
    )

    $child = New-RichTree -Label $Label -GuideStyle $Tree.GuideStyle
    $Tree.Children.Add($child)
    return $child
}

function Format-RichTree {
    <#
    .SYNOPSIS
        Renders a Rich Tree to a list of strings.
    .DESCRIPTION
        Recursively renders the tree structure with guide lines and styles.
    .PARAMETER Tree
        The tree object to render.
    .PARAMETER Prefixes
        Internal use: The prefixes for the current level of the tree.
    #>
    param(
        [Parameter(Mandatory = $true)]
        $Tree,

        [string[]]$Prefixes = @()
    )

    $output = [System.Collections.Generic.List[string]]::new()
    
    # Render the current node's label
    $labelLine = ""
    if ($Prefixes.Count -gt 0) {
        $labelLine = ($Prefixes -join "")
    }
    $labelLine += (Convert-RichMarkup $Tree.Label)
    $output.Add($labelLine)

    $guideStyle = Get-AnsiCode $Tree.GuideStyle
    $reset = Get-AnsiCode "reset"

    $childCount = $Tree.Children.Count
    for ($i = 0; $i -lt $childCount; $i++) {
        $child = $Tree.Children[$i]
        $isLast = ($i -eq ($childCount - 1))

        $newPrefixes = [System.Collections.Generic.List[string]]::new()
        foreach ($p in $Prefixes) {
            # Replace the last part of the prefix for the next level
            if ($p -eq "$guideStyle├── $reset") {
                $newPrefixes.Add("$guideStyle│   $reset")
            }
            elseif ($p -eq "$guideStyle└── $reset") {
                $newPrefixes.Add("    ")
            }
            else {
                $newPrefixes.Add($p)
            }
        }

        $currentPrefix = if ($isLast) { "$guideStyle└── $reset" } else { "$guideStyle├── $reset" }
        
        # Recursive call
        $childOutput = Format-RichTree -Tree $child -Prefixes ($newPrefixes + $currentPrefix)
        foreach ($line in $childOutput) {
            $output.Add($line)
        }
    }

    return $output
}
