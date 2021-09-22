function Get-AbrOntapRepClusterPeer {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP Replication information from the Cluster Management Network
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
        Write-PscriboMessage "Collecting ONTAP Replication information."
    }

    process {
        $ReplicaData = Get-NcClusterPeer
        $ReplicaObj = @()
        if ($ReplicaData) {
            foreach ($Item in $ReplicaData) {
                $inObj = [ordered] @{
                    'Cluster Peer' = $Item.RemoteClusterName
                    'Cluster Nodes' = $Item.RemoteClusterNodes
                    'Peer Addresses' = $Item.PeerAddresses
                    'Cluster Health' = $Item.IsClusterHealthy
                    'IP Space' = $Item.IpspaceName
                    'Status' = ($Item.Availability).toUpper()
                }
                $ReplicaObj += [pscustomobject]$inobj
            }
            if ($Healthcheck.Replication.ClusterPeer) {
                $ReplicaObj | Where-Object { $_.'Status' -notlike 'Available' } | Set-Style -Style Warning -Property 'Status'
            }

            $TableParams = @{
                Name = "Replication - Cluster Peer Information - $($ClusterInfo.ClusterName)"
                List = $false
                ColumnWidths = 20, 20, 20, 10, 15, 15
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $ReplicaObj | Table @TableParams
        }
    }

    end {}

}