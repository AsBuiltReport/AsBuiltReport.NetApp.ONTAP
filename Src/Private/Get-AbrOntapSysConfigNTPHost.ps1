function Get-AbrOntapSysConfigNTPHost {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP System NTP Host Status information from the Cluster Management Network
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
        Write-PScriboMessage "Collecting ONTAP System NTP Host Status information."
    }

    process {
        try {
            $Data = Get-NcNtpServerStatus -Controller $Array
            $OutObj = @()
            if ($Data) {
                foreach ($Item in $Data) {
                    try {
                        $inObj = [ordered] @{
                            'Node' = $Item.Node
                            'Time Offset' = $Item.Offset
                            'Selection State' = $Item.SelectionState
                            'Server' = $Item.Server
                            'Peer Status' = switch ($Item.IsPeerReachable) {
                                'True' { 'Reachable' }
                                'False' { 'Unreachable' }
                                default { $Item.IsPeerReachable }
                            }
                        }
                        $OutObj += [pscustomobject]$inobj
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }
                if ($Healthcheck.System.NTP) {
                    $OutObj | Where-Object { $_.'Peer Status' -notlike 'Reachable' } | Set-Style -Style Warning -Property 'Peer Status'
                }

                $TableParams = @{
                    Name = "NTP Host Status - $($ClusterInfo.ClusterName)"
                    List = $false
                    ColumnWidths = 30, 10, 25, 20, 15
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $OutObj | Table @TableParams
                if ($Healthcheck.System.NTP -and ($OutObj | Where-Object { $_.'Peer Status' -notlike 'Reachable' })) {
                    Paragraph "Health Check:" -Bold -Underline
                    BlankLine
                    Paragraph {
                        Text "Best Practice:" -Bold
                        Text "Ensure that all configured NTP servers are reachable to maintain accurate time synchronization across the cluster."
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