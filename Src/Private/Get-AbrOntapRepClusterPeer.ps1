function Get-AbrOntapRepClusterPeer {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP Replication information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.6.8
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
        Write-PScriboMessage "Collecting ONTAP Replication information."
    }

    process {
        try {
            $ReplicaData = Get-NcClusterPeer -Controller $Array
            $ReplicaObj = @()
            if ($ReplicaData) {
                foreach ($Item in $ReplicaData) {
                    try {
                        $inObj = [ordered] @{
                            'Cluster Peer' = $Item.RemoteClusterName
                            'Cluster Nodes' = $Item.RemoteClusterNodes
                            'Peer Addresses' = $Item.PeerAddresses
                            'Cluster Health' = $Item.IsClusterHealthy
                            'IP Space' = $Item.IpspaceName
                            'Status' = ($Item.Availability)
                        }
                        $ReplicaObj += [pscustomobject]$inobj
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }
                if ($Healthcheck.Replication.ClusterPeer) {
                    $ReplicaObj | Where-Object { $_.'Status' -notlike 'Available' } | Set-Style -Style Warning -Property 'Status'
                }

                $TableParams = @{
                    Name = "Cluster Peer - $($ClusterInfo.ClusterName)"
                    List = $false
                    ColumnWidths = 20, 20, 19, 10, 15, 16
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $ReplicaObj | Table @TableParams
            }
        } catch {
            Write-PScriboMessage -IsWarning $_.Exception.Message
        }
    }

    end {}

}