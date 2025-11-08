function Get-AbrOntapRepHistory {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP SnapMirror replication history information from the Cluster Management Network
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
        Write-PScriboMessage "Collecting ONTAP SnapMirror replication history information."
    }

    process {
        try {
            $ReplicaData = Get-NcSnapmirrorHistory -Controller $Array
            $ReplicaObj = @()
            if ($ReplicaData) {
                foreach ($Item in $ReplicaData) {
                    try {
                        $inObj = [ordered] @{
                            'Source Location' = $Item.SourceLocation
                            'Destination Location' = $Item.DestinationLocation
                            'Operation Type' = $Item.OperationType
                            'Result' = $Item.Result
                            'Start' = $Item.Start
                        }
                        $ReplicaObj += [pscustomobject]$inobj
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }
                if ($Healthcheck.Replication.History) {
                    $ReplicaObj | Where-Object { $_.'Result' -ne 'success' } | Set-Style -Style Warning -Property 'Result'
                }

                $TableParams = @{
                    Name = "SnapMirror Replication History - $($ClusterInfo.ClusterName)"
                    List = $false
                    ColumnWidths = 25, 25, 15, 15, 20
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $ReplicaObj | Table @TableParams
                if ($Healthcheck.Replication.History -and ($ReplicaObj | Where-Object { $_.'Result' -ne 'success' })) {
                    Paragraph "Health Check:" -Bold -Underline
                    BlankLine
                    Paragraph {
                        Text "Best Practice:" -Bold
                        Text "Ensure that all SnapMirror replication operations complete successfully to maintain data integrity."
                    }
                    BlankLine
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning $_.Exception.Message
        }
    }

    end {}

}