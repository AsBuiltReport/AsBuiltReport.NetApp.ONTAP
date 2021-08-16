function Get-AbrOntapRepRelationship {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP SnapMirror relationship information from the Cluster Management Network
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
        Write-PscriboMessage "Collecting ONTAP SnapMirror relationship information."
    }

    process {
        $ReplicaData = Get-NcSnapmirror
        $ReplicaObj = @()
        if ($ReplicaData) {
            foreach ($Item in $ReplicaData) {
                $inObj = [ordered] @{
                    'Source Vserver' = $Item.SourceVserver
                    'Source Location' = $Item.SourceLocation
                    'Destination Vserver' = $Item.DestinationVserver
                    'Destination Location' = $Item.DestinationLocation
                    'Mirror State' = $Item.MirrorState
                    'Schedule' = ($Item.Schedule).toUpper()
                    'Relationship Type' = Switch ($Item.RelationshipType) {
                        'extended_data_protection' { 'XDP' }
                        'data_protection' { 'DP' }
                        'transition_data_protection' { 'TDP' }
                        'restore' { 'RST' }
                        'load_sharing' { 'LS' }
                    }
                    'Policy' = $Item.Policy
                    'Policy Type' = $Item.PolicyType
                    'Unhealthy Reason' = $Item.UnhealthyReason
                    'Lag Time' = [timespan]::fromseconds($Item.LagTime).tostring()
                    'Status' = ($Item.Status).toUpper()
                }
                $ReplicaObj += [pscustomobject]$inobj
            }
            if ($Healthcheck.Replication.Relationship) {
                $ReplicaObj | Where-Object { $NULL -ne $_.'Unhealthy Reason' } | Set-Style -Style Warning -Property 'Unhealthy Reason'
            }

            $TableParams = @{
                Name = "Replication - SnapMirror relationship Information - $($ClusterInfo.ClusterName)"
                List = $true
                ColumnWidths = 30, 70
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $ReplicaObj | Table @TableParams
        }
    }

    end {}

}