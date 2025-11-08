function Get-AbrOntapVserverFcpAdapter {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP Vserver FCP adapter information from the Cluster Management Network
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
        Write-PScriboMessage "Collecting ONTAP Vserver FCP adapter information."
    }

    process {
        try {
            $VserverData = Get-NcFcpAdapter -Controller $Array | Where-Object { $_.PhysicalProtocol -ne 'ethernet' }
            $VserverObj = @()
            if ($VserverData) {
                foreach ($Item in $VserverData) {
                    try {
                        $inObj = [ordered] @{
                            'Node Name' = $Item.Node
                            'Adapter' = $Item.Adapter
                            'Protocol' = $Item.PhysicalProtocol
                            'Speed' = $Item.Speed
                            'Status' = switch ($Item.State) {
                                'online' { 'Up' }
                                'offline' { 'Down' }
                                default { $Item.State }
                            }
                        }
                        $VserverObj += [pscustomobject]$inobj
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }
                if ($Healthcheck.Vserver.FCP) {
                    $VserverObj | Where-Object { $_.'Status' -like 'Down' } | Set-Style -Style Warning -Property 'Status'
                }

                $TableParams = @{
                    Name = "FCP Physical Adapter - $($ClusterInfo.ClusterName)"
                    List = $false
                    ColumnWidths = 32, 17, 17, 17, 17
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $VserverObj | Table @TableParams
                if ($Healthcheck.Vserver.FCP -and ($VserverObj | Where-Object { $_.'Status' -like 'Down' })) {
                    Paragraph "Health Check:" -Bold -Underline
                    BlankLine
                    Paragraph {
                        Text "Best Practice:" -Bold
                        Text "Ensure that all FCP adapters are operational to maintain optimal storage connectivity."
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