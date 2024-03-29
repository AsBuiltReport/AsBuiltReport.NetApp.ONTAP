function Get-AbrOntapSecurityKMS {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP Security Key Management Service information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.6.7
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
        Write-PScriboMessage "Collecting ONTAP Security Key Management Service information."
    }

    process {
        try {
            $Data = Get-NcSecurityKeyManagerKeyStore -Controller $Array
            $OutObj = @()
            if ($Data) {
                foreach ($Item in $Data) {
                    try {
                        $inObj = [ordered] @{
                            'Cluster IP' = $Item.NcController
                            'Key Store' = $TextInfo.ToTitleCase($Item.KeyStore)
                            'Vserver' = $Item.Vserver
                        }
                        $OutObj += [pscustomobject]$inobj
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }

                $TableParams = @{
                    Name = "Key Management Service (KMS) - $($ClusterInfo.ClusterName)"
                    List = $false
                    ColumnWidths = 30, 30, 40
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $OutObj | Table @TableParams
            }
        } catch {
            Write-PScriboMessage -IsWarning $_.Exception.Message
        }
    }

    end {}

}