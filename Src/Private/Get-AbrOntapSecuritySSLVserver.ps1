function Get-AbrOntapSecuritySSLVserver {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP Security Vserver SSL information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.4.0
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
        Write-PscriboMessage "Collecting ONTAP Security Vserver SSL information."
    }

    process {
        $Data =  Get-NcSecuritySsl
        $OutObj = @()
        if ($Data) {
            foreach ($Item in $Data) {
                $inObj = [ordered] @{
                    'Common Name' = $Item.CommonName
                    'Certificate Authority' = $Item.CertificateAuthority
                    'Client Auth' = ConvertTo-TextYN $Item.ClientAuth
                    'Server Auth' = ConvertTo-TextYN $Item.ServerAuth
                    'Serial Number' = $Item.CertificateSerialNumber
                    'Vserver' = $Item.Vserver
                }
                $OutObj += [pscustomobject]$inobj
            }

            $TableParams = @{
                Name = "Per Vserver SSL information  - $($ClusterInfo.ClusterName)"
                List = $false
                ColumnWidths = 20, 19, 8, 8, 25, 20
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $OutObj | Table @TableParams
        }
    }

    end {}

}