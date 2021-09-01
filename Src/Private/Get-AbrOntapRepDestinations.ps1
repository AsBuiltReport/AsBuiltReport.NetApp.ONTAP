function Get-AbrOntapRepDestinations {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP SnapMirror Destination relationship information from the Cluster Management Network
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
        Write-PscriboMessage "Collecting ONTAP SnapMirror Destination relationship information."
    }

    process {
        $ReplicaData = Get-NcSnapmirrorDestination
        $ReplicaObj = @()
        if ($ReplicaData) {
            foreach ($Item in $ReplicaData) {
                if ($Item.RelationshipStatus) {
                    $Item.RelationshipStatus = ($Item.RelationshipStatus).toUpper()
                }
                $inObj = [ordered] @{
                    'Destination Vserver' = $Item.DestinationVserver
                    'Destination Location' = $Item.DestinationLocation
                    'Source Vserver' = $Item.SourceVserver
                    'Source Location' = $Item.SourceLocation
                    'Relationship Type' = Switch ($Item.RelationshipType) {
                        'extended_data_protection' { 'XDP' }
                        'data_protection' { 'DP' }
                        'transition_data_protection' { 'TDP' }
                        'restore' { 'RST' }
                        'load_sharing' { 'LS' }
                    }
                    'Policy Type' = $Item.PolicyType
                    'Status' = Switch ($Item.RelationshipStatus) {
                        $Null { 'Unknown' }
                        default { $Item.RelationshipStatus }
                    }
                }
                $ReplicaObj += [pscustomobject]$inobj
            }
            if ($Healthcheck.Replication.Relationship) {
                $ReplicaObj | Where-Object { $_.'Status' -eq "Unknown" } | Set-Style -Style Warning -Property 'Status'
            }

            $TableParams = @{
                Name = "Replication - SnapMirror Destination (List-Destinations) Information - $($ClusterInfo.ClusterName)"
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