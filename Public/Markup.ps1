
function Convert-RichMarkup {
    <#
    .SYNOPSIS
        Converts Rich markup tags to ANSI escape sequences.
    .DESCRIPTION
        Processes strings containing tags like [bold red]text[/] and replaces them with the corresponding ANSI escape sequences for console display.
    .PARAMETER InputString
        The string containing Rich markup tags. Supports pipeline input.
    .EXAMPLE
        Convert-RichMarkup "[yellow]Warning:[/] [bold]System update required[/]"
    #>
    param(
        [Parameter(ValueFromPipeline = $true, Position = 0)]
        [string]$InputString
    )

    if ([string]::IsNullOrEmpty($InputString)) { return "" }

    # Simple regex to find [style]text[/] or [style]text[/style]
    $pattern = '\[([a-z ]+)\](.*?)\[\/\1?\]'
    
    $result = [regex]::Replace($InputString, $pattern, {
            param($match)
            $style = $match.Groups[1].Value
            $text = $match.Groups[2].Value
            return Format-RichText -Text $text -Style $style
        })

    # Handle the [/] shorthand for closing the last tag
    # This is more complex for a single regex, so we'll do a simple pass for now.
    # For a true port, we'd need a stack-based parser.
    
    return $result
}

