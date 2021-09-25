function Get-AbrOntapSecurityKMSExt {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP Security Key Management Service External information from the Cluster Management Network
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
        Write-PscriboMessage "Collecting ONTAP Security Key Management Service External information."
    }

    process {
        $Data = Get-NcSecurityKeyManagerExternal
        $OutObj = @()
        if ($Data) {
            foreach ($Item in $Data) {
                $inObj = [ordered] @{
                    'Key Server' = $Item.KeyServer
                    'Client Cert' = $Item.ClientCert
                    'Server Ca Certs' = $Item.ServerCaCerts
                    'Timeout' = $Item.Timeout
                    'Vserver' = $Item.Vserver
                }
                $OutObj += [pscustomobject]$inobj
            }

            $TableParams = @{
                Name = "External Key Management Service (KMS) information  - $($ClusterInfo.ClusterName)"
                List = $false
                ColumnWidths = 30, 20, 20, 10, 20
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $OutObj | Table @TableParams
        }
    }

    end {}

}