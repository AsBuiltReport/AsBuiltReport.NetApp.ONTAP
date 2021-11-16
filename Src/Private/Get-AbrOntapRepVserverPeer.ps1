function Get-AbrOntapRepVserverPeer {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP Vserver Peer information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.5.0
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
        Write-PscriboMessage "Collecting ONTAP Vserver Peer information."
    }

    process {
        $ReplicaData = Get-NcVserverPeer -Controller $Array
        $ReplicaObj = @()
        if ($ReplicaData) {
            foreach ($Item in $ReplicaData) {
                $inObj = [ordered] @{
                    'Vserver' = $Item.Vserver
                    'Peer Vserver' = $Item.PeerVserver
                    'Peer Cluster' = $Item.PeerCluster
                    'Applications' = $Item.Applications
                    'Peer State' = $Item.PeerState
                }
                $ReplicaObj += [pscustomobject]$inobj
            }
            if ($Healthcheck.Replication.VserverPeer) {
                $ReplicaObj | Where-Object { $_.'Peer State' -notlike 'peered' } | Set-Style -Style Warning -Property 'Peer State'
            }

            $TableParams = @{
                Name = "Replication - Vserver Peer Information - $($ClusterInfo.ClusterName)"
                List = $false
                ColumnWidths = 20, 20, 20 ,20, 20
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $ReplicaObj | Table @TableParams
        }
    }

    end {}

}