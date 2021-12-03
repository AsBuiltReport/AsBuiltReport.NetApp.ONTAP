function Get-AbrOntapSecuritySSLDetailed {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP Security Vserver SSL Detailed information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.5.0
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
        Write-PscriboMessage "Collecting ONTAP Security Vserver SSL Detailed information."
    }

    process {
        $Data =  Get-NcSecurityCertificate -Controller $Array | Where-Object {$_.Type -eq "server"}
        $OutObj = @()
        if ($Data) {
            foreach ($Item in $Data) {
                $inObj = [ordered] @{
                    'Common Name' = $Item.CommonName
                    'Protocol' = $Item.Protocol
                    'Hash Function' = $Item.HashFunction
                    'Serial Number' = $Item.SerialNumber
                    'Expiration' = ($Item.ExpirationDateDT).ToString().Split(" ")[0]
                    'Vserver' = $Item.Vserver
                }
                $OutObj += [pscustomobject]$inobj
            }

            $TableParams = @{
                Name = "SSL Detailed information  - $($ClusterInfo.ClusterName)"
                List = $false
                ColumnWidths = 18, 10, 10, 25, 19, 18
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $OutObj | Table @TableParams
        }
    }

    end {}

}