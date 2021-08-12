function Get-AbrOntapVserverS3Summary {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP Vserver S3 information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.1.0
        Author:         Jonathan Colon
        Twitter:        @jcolonfzenpr
        Github:         rebelinux
    .EXAMPLE

    .LINK

    #>
    [CmdletBinding()]
    param (
    )

    begin {
        Write-PscriboMessage "Collecting ONTAP Vserver S3 information."
    }

    process {
        $VserverData = Get-AbrOntapApi -uri "/api/protocols/s3/services?"
        $VserverObj = @()
        if ($VserverData) {
            foreach ($Item in $VserverData) {
                $inObj = [ordered] @{
                    'Vserver' = $Item.Name
                    'HTTP' = $Item.is_http_enabled
                    'HTTP Port' = $Item.port
                    'HTTPS' = $Item.is_https_enabled
                    'HTTPS Port' = $Item.secure_port
                    'Status' = switch ($Item.enabled) {
                        'True' { 'UP' }
                        'False' { 'Down' }
                    }
                }
                $VserverObj += [pscustomobject]$inobj
            }

            $TableParams = @{
                Name = "Vserver S3 Service Information - $($ClusterInfo.ClusterName)"
                List = $false
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $VserverObj | Table @TableParams
        }
    }

    end {}

}