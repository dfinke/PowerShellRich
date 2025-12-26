
function Write-Rich {
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
