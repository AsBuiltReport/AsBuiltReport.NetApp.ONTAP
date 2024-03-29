function Get-AbrOntapRepVserverPeer {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP Vserver Peer information from the Cluster Management Network
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
        Write-PScriboMessage "Collecting ONTAP Vserver Peer information."
    }

    process {
        try {
            $ReplicaData = Get-NcVserverPeer -Controller $Array
            $ReplicaObj = @()
            if ($ReplicaData) {
                foreach ($Item in $ReplicaData) {
                    try {
                        $inObj = [ordered] @{
                            'Vserver' = $Item.Vserver
                            'Peer Vserver' = $Item.PeerVserver
                            'Peer Cluster' = $Item.PeerCluster
                            'Applications' = $Item.Applications
                            'Peer State' = $Item.PeerState
                        }
                        $ReplicaObj += [pscustomobject]$inobj
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }
                if ($Healthcheck.Replication.VserverPeer) {
                    $ReplicaObj | Where-Object { $_.'Peer State' -notlike 'peered' } | Set-Style -Style Warning -Property 'Peer State'
                }

                $TableParams = @{
                    Name = "Peer - $($ClusterInfo.ClusterName)"
                    List = $false
                    ColumnWidths = 20, 20, 20 , 20, 20
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