function Get-AbrOntapNetworkRouteLifs {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP network route per lif information from the Cluster Management Network
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
        Write-PscriboMessage "Collecting ONTAP network route per lif information."
    }

    process {
        $Routes = Get-NcNetRouteLif
        $RoutesObj = @()
        if ($Routes) {
            foreach ($Item in $Routes) {
                $inObj = [ordered] @{
                    'Destination' = $Item.Destination
                    'Gateway' = $Item.Gateway
                    'Lif Names' = $Item.LifNames
                    'Vserver' = $Item.Vserver
                }
                $RoutesObj += [pscustomobject]$inobj
            }

            $TableParams = @{
                Name = "Per Network Interface Route Information - $($ClusterInfo.ClusterName)"
                List = $false
                ColumnWidths = 20, 20, 40, 20
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $RoutesObj | Table @TableParams
        }
    }

    end {}

}