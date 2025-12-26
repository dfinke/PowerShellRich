
function Write-Rich {
    param(
        [Parameter(ValueFromPipeline)]
        [string]$InputObject,
        
        [string]$Style
    )

    process {
        $text = $InputObject
        if ($Style) {
            $text = Format-RichText -Text $text -Style $Style
        }
        
        $formatted = Convert-RichMarkup -InputString $text
        Write-Host $formatted
    }
}
