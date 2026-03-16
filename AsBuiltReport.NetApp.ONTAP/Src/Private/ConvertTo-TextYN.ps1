function ConvertTo-TextYN {
    <#
    .SYNOPSIS
    Used by As Built Report to convert true or false automatically to Yes or No.
    .DESCRIPTION

    .NOTES
        Version:        0.2.0
        Author:         LEE DAILEY

    .EXAMPLE

    .LINK

    #>
    [CmdletBinding()]
    [OutputType([String])]
    param
    (
        [Parameter (
            Position = 0,
            Mandatory)]
        [AllowEmptyString()]
        [string]
        $TEXT
    )

    switch ([string]::IsNullOrEmpty($TEXT)) {
        $true { '--' }
        $false {
            switch ($TEXT) {
                'True' { 'Yes'; break }
                'False' { 'No'; break }
                default { $TEXT }
            }
        }
        default { '--' }
    }
} # end