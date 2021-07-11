function Get-AbrOntapNetworkBdomain {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP Network Broadcast Domain information from the Cluster Management Network
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
        Write-PscriboMessage "Collecting ONTAP Broadcast information."
    }

    process {
        $BDomain = Get-NcNetPortBroadcastDomain
        $BDomainObj = @()
        if ($BDomain) {
            foreach ($Item in $BDomain) {
                $inObj = [ordered] @{
                    'Name' = $Item.BroadcastDomain
                    'Ipspace' = $Item.Ipspace
                    'Failover Groups' = $Item.FailoverGroups
                    'Mtu' = $Item.Mtu
                    'Ports' = $Item.Ports
                }
                $BDomainObj += [pscustomobject]$inobj
            }

            $TableParams = @{
                Name = "Network Broadcast Domain Information - $($ClusterInfo.ClusterName)"
                List = $false
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $BDomainObj | Table @TableParams
        }
    }

    end {}

}