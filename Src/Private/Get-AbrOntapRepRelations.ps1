function Get-AbrOntapRepRelationship {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP SnapMirror relationship information from the Cluster Management Network
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
        Write-PScriboMessage "Collecting ONTAP SnapMirror relationship information."
    }

    process {
        try {
            $ReplicaData = Get-NcSnapmirror -Controller $Array
            $ReplicaObj = @()
            if ($ReplicaData) {
                foreach ($Item in $ReplicaData) {
                    try {
                        $lag = [timespan]::fromseconds($Item.LagTime).tostring()
                        $time = $lag.Split(".").Split(":")
                        $lagtime = $time[0] + " days, " + $time[1] + " hrs, " + $time[2] + " mins, " + $time[0] + " secs"
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
                                default { $Item.RelationshipType }
                            }
                            'Policy' = $Item.Policy
                            'Policy Type' = $Item.PolicyType
                            'Unhealthy Reason' = Switch ($Item.UnhealthyReason) {
                                $NULL { "None" }
                                default { $Item.UnhealthyReason }
                            }
                            'Lag Time' = $lagtime
                            'Status' = ($Item.Status).toUpper()
                        }
                        $ReplicaObj = [pscustomobject]$inobj

                        if ($Healthcheck.Replication.Relationship) {
                            $ReplicaObj | Where-Object { $_.'Unhealthy Reason' -ne "None" } | Set-Style -Style Warning -Property 'Unhealthy Reason'
                        }

                        $TableParams = @{
                            Name = "SnapMirror relationship - $($Item.SourceLocation)"
                            List = $true
                            ColumnWidths = 30, 70
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $ReplicaObj | Table @TableParams
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