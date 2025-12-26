
function Write-Rich {
    <#
    .SYNOPSIS
        Writes formatted text to the console.
    .DESCRIPTION
        Writes text to the console with support for Rich markup and automatic formatting of Rich objects (Tables, Trees, Layouts).
    .PARAMETER InputObject
        The object or text to write. Supports pipeline input.
    .PARAMETER Style
        An optional style to apply to the entire output (e.g., "bold red").
    .EXAMPLE
        Write-Rich "[bold red]Hello[/] [green]World[/]"
    .EXAMPLE
        New-RichTable -Title "My Table" | Write-Rich
    #>
    param(
        [Parameter(ValueFromPipeline)]
        $InputObject,
        
        [string]$Style
    )

    process {
        $text = $InputObject
        
        if ($null -ne $InputObject -and $InputObject -is [PSCustomObject]) {
            if ($InputObject._Type -eq "RichTable") {
                $text = Format-RichTable -Table $InputObject
            }
            elseif ($InputObject._Type -eq "RichTree") {
                $text = (Format-RichTree -Tree $InputObject) -join "`n"
            }
            elseif ($InputObject._Type -eq "RichLayout") {
                $text = (Format-RichLayout -Layout $InputObject) -join "`n"
            }
        }

        if ($Style) {
            $text = Format-RichText -Text ([string]$text) -Style $Style
        }
        
        $formatted = Convert-RichMarkup -InputString ([string]$text)
        Write-Host $formatted
    }
}
