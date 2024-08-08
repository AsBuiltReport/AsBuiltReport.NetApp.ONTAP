function Get-AbrOntapRepMediator {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP SnapMirror Mediator relationship information from the Cluster Management Network
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
        Write-PScriboMessage "Collecting ONTAP SnapMirror Mediator relationship information."
    }

    process {
        try {
            $ReplicaData = Get-NetAppOntapAPI -uri "/api/cluster/mediators?fields=*&return_records=true&return_timeout=15"
            $ReplicaObj = @()
            if ($ReplicaData) {
                foreach ($Item in $ReplicaData) {
                    try {
                        $inObj = [ordered] @{
                            'Peer cluster' = $Item.peer_cluster.name
                            'IP Address' = $Item.ip_address
                            'port' = $Item.port
                            'Status' = Switch ($Item.reachable) {
                                'True' { 'Reachable' }
                                'False' { 'Unreachable' }
                                default { $Item.reachable }
                            }
                        }
                        $ReplicaObj += [pscustomobject]$inobj
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }
                if ($Healthcheck.Replication.Mediator) {
                    $ReplicaObj | Where-Object { $_.'Status' -eq "Unreachable" } | Set-Style -Style Critical -Property 'Status'
                }

                $TableParams = @{
                    Name = "SnapMirror Mediator - $($ClusterInfo.ClusterName)"
                    List = $false
                    ColumnWidths = 25, 25, 25, 25
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