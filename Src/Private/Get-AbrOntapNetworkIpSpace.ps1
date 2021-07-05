function Get-AbrOntapNetworkIpSpace {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP Network IpSpace information from the Cluster Management Network
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
        Write-PscriboMessage "Collecting ONTAP IPSpace information."
    }

    process {
        $IPSpace = Get-NcNetIpspace
        $IPSpaceObj = @()
        if ($IPsPace) {
            foreach ($Item in $IPSpace) {
                $inObj = [ordered] @{
                    'Name' = $Item.Ipspace
                    'SVM' = $Item.Vservers
                    'Ports' = $Item.Ports
                    'Broadcast Domains' = $Item.BroadcastDomains
                }
                $IPSpaceObj += [pscustomobject]$inobj
            }
            if ($Healthcheck.Network.Port) {
                $IPSpaceObj | Where-Object { $_.'Port' -match "Down" } | Set-Style -Style Warning -Property 'Port'
                $IPSpaceObj | Where-Object { $_.'Port Participation' -ne "full" } | Set-Style -Style Warning -Property 'Port Participation'
            }


            $TableParams = @{
                Name = "Network IPSpace Information - $($ClusterInfo.ClusterName)"
                List = $true
                ColumnWidths = 25, 75
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $IPSpaceObj | Table @TableParams
        }
    }

    end {}

}