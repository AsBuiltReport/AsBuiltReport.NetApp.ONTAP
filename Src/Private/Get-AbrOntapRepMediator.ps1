function Get-AbrOntapRepMediator {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP SnapMirror Mediator relationship information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.3.0
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
        Write-PscriboMessage "Collecting ONTAP SnapMirror Mediator relationship information."
    }

    process {
        $ReplicaData = Get-AbrOntapApi -uri "/api/cluster/mediators?"
        $ReplicaObj = @()
        if ($ReplicaData) {
            foreach ($Item in $ReplicaData) {
                $inObj = [ordered] @{
                    'Peer cluster' = $Item.peer_cluster.name
                    'IP Address' = $Item.ip_address
                    'port' = $Item.port
                    'Status' = Switch ($Item.reachable) {
                        'True' { 'Reachable' }
                        'False' { 'Unreachable' }
                    }
                }
                $ReplicaObj += [pscustomobject]$inobj
            }
            if ($Healthcheck.Replication.Mediator) {
                $ReplicaObj | Where-Object { $_.'Status' -eq "Unreachable"} | Set-Style -Style Critical -Property 'Status'
            }

            $TableParams = @{
                Name = "Replication - SnapMirror Mediator Information - $($ClusterInfo.ClusterName)"
                List = $false
                ColumnWidths = 25, 25, 25, 25
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $ReplicaObj | Table @TableParams
        }
    }

    end {}

}