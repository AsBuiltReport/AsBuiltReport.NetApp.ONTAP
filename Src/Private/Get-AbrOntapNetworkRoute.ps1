function Get-AbrOntapNetworkRoutes {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP network rRoute information from the Cluster Management Network
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
        Write-PscriboMessage "Collecting ONTAP network route information."
    }

    process {
        $Routes = Get-NcNetRoute
        $RoutesObj = @()
        if ($Vlan) {
            foreach ($Item in $Routes) {
                $inObj = [ordered] @{
                    'Destination' = $Item.Destination
                    'Gateway' = $Item.Gateway
                    'Metric' = $Item.Metric
                    'Vserver' = $Item.Vserver
                }
                $RoutesObj += [pscustomobject]$inobj
            }

            $TableParams = @{
                Name = "Network Route Information - $($ClusterInfo.ClusterName)"
                List = $false
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $RoutesObj | Table @TableParams
        }
    }

    end {}

}