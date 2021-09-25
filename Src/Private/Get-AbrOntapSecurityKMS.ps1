function Get-AbrOntapSecurityKMS {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP Security Key Management Service information from the Cluster Management Network
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
        Write-PscriboMessage "Collecting ONTAP Security Key Management Service information."
    }

    process {
        $Data = Get-NcSecurityKeyManagerKeyStore
        $OutObj = @()
        if ($Data) {
            foreach ($Item in $Data) {
                $inObj = [ordered] @{
                    'Cluster IP' = $Item.NcController
                    'Key Store' = $TextInfo.ToTitleCase($Item.KeyStore)
                    'Vserver' = $Item.Vserver
                }
                $OutObj += [pscustomobject]$inobj
            }

            $TableParams = @{
                Name = "Key Management Service (KMS) information  - $($ClusterInfo.ClusterName)"
                List = $false
                ColumnWidths = 30, 30, 40
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $OutObj | Table @TableParams
        }
    }

    end {}

}