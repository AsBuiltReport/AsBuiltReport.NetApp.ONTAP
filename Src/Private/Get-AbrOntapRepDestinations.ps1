function Get-AbrOntapRepDestination {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP SnapMirror Destination relationship information from the Cluster Management Network
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
        Write-PScriboMessage "Collecting ONTAP SnapMirror Destination relationship information."
    }

    process {
        try {
            $ReplicaData = Get-NcSnapmirrorDestination -Controller $Array
            $ReplicaObj = @()
            if ($ReplicaData) {
                foreach ($Item in $ReplicaData) {
                    try {
                        if ($Item.RelationshipStatus) {
                            $Item.RelationshipStatus = ($Item.RelationshipStatus)
                        }
                        $inObj = [ordered] @{
                            'Destination Vserver' = $Item.DestinationVserver
                            'Destination Location' = $Item.DestinationLocation
                            'Source Vserver' = $Item.SourceVserver
                            'Source Location' = $Item.SourceLocation
                            'Relationship Type' = switch ($Item.RelationshipType) {
                                'extended_data_protection' { 'XDP' }
                                'data_protection' { 'DP' }
                                'transition_data_protection' { 'TDP' }
                                'restore' { 'RST' }
                                'load_sharing' { 'LS' }
                                default { $Item.RelationshipType }
                            }
                            'Policy Type' = $Item.PolicyType
                            'Status' = switch ($Item.RelationshipStatus) {
                                $Null { 'Unknown' }
                                default { $Item.RelationshipStatus }
                            }
                        }
                        $ReplicaObj = [pscustomobject]$inobj

                        if ($Healthcheck.Replication.Relationship) {
                            $ReplicaObj | Where-Object { $_.'Status' -eq "Unknown" } | Set-Style -Style Warning -Property 'Status'
                        }

                        $TableParams = @{
                            Name = "SnapMirror Destination (List-Destinations) - $($Item.DestinationLocation)"
                            List = $true
                            ColumnWidths = 30, 70
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $ReplicaObj | Table @TableParams
                        if ($Healthcheck.Replication.Relationship -and ($ReplicaObj | Where-Object { $_.'Status' -eq "Unknown" })) {
                            Paragraph "Health Check:" -Bold -Underline
                            BlankLine
                            Paragraph {
                                Text "Best Practice:" -Bold
                                Text "Ensure that all SnapMirror relationships have a known status to maintain replication integrity."
                            }
                            BlankLine
                        }
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning $_.Exception.Message
        }
    }

    end {}

}