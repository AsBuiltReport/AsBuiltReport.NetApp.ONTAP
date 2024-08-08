function Get-AbrOntapVserverS3Summary {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP Vserver S3 information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.6.7
        Author:         Jonathan Colon
        Twitter:        @jcolonfzenpr
        Github:         rebelinux
    .EXAMPLE

    .LINK

    #>
    param (
        [Parameter (
            Position = 0,
            Mandatory)]
        [string]
        $Vserver
    )

    begin {
        Write-PScriboMessage "Collecting ONTAP Vserver S3 information."
    }

    process {
        try {
            $VserverData = Get-NetAppOntapAPI -uri "/api/protocols/s3/services?svm=$Vserver&fields=*&return_records=true&return_timeout=15"
            $VserverObj = @()
            if ($VserverData) {
                foreach ($Item in $VserverData) {
                    try {
                        $inObj = [ordered] @{
                            'HTTP' = ConvertTo-TextYN $Item.is_http_enabled
                            'HTTP Port' = $Item.port
                            'HTTPS' = ConvertTo-TextYN $Item.is_https_enabled
                            'HTTPS Port' = $Item.secure_port
                            'Status' = Switch ($Item.enabled) {
                                'True' { 'UP' }
                                'False' { 'Down' }
                                default { $Item.enabled }
                            }
                        }
                        $VserverObj += [pscustomobject]$inobj
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }

                $TableParams = @{
                    Name = "S3 Service - $($Vserver)"
                    List = $false
                    ColumnWidths = 20, 20, 20, 20, 20
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $VserverObj | Table @TableParams
            }
        } catch {
            Write-PScriboMessage -IsWarning $_.Exception.Message
        }
    }

    end {}

}