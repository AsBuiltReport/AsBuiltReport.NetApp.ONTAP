function Get-AbrOntapVserverLunIgroup {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP vserver igroup information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.6.7
        Author:         Jonathan Colon
        Twitter:        @jcolonfzenpr
        Github:         rebelinux
    .EXAMPLE

    .LINK

    #>
    param (
        [Parameter (
            Position = 0,
            Mandatory)]
        [string]
        $Vserver
    )

    begin {
        Write-PScriboMessage "Collecting ONTAP Vserver Igroup information."
    }

    process {
        try {
            $VserverIgroup = Get-NcIgroup -VserverContext $Vserver -Controller $Array
            $VserverObj = @()
            if ($VserverIgroup) {
                foreach ($Item in $VserverIgroup) {
                    try {
                        $lunmap = Get-NcLunMap -Controller $Array | Where-Object { $_.InitiatorGroup -eq $Item.Name } | Select-Object -ExpandProperty Path
                        $reportingnodes = Get-NcLunMap -Controller $Array | Where-Object { $_.InitiatorGroup -eq $Item.Name } | Select-Object -Unique -ExpandProperty ReportingNodes
                        $MappedLun = @()
                        foreach ($lun in $lunmap) {
                            try {
                                $lunname = $lun.split('/')
                                $MappedLun += $lunname[3]
                            } catch {
                                Write-PScriboMessage -IsWarning $_.Exception.Message
                            }
                        }
                        $inObj = [ordered] @{
                            'Igroup Name' = $Item.Name
                            'Type' = $Item.Type
                            'Protocol' = $Item.Protocol
                            'Initiators' = $Item.Initiators.InitiatorName
                            'Mapped Lun' = switch (($MappedLun).count) {
                                0 { "None" }
                                default { $MappedLun }
                            }
                            'Reporting Nodes' = switch (($reportingnodes).count) {
                                0 { "None" }
                                default { $reportingnodes }
                            }
                        }
                        $VserverObj = [pscustomobject]$inobj
                        if ($Healthcheck.Vserver.Status) {
                            $VserverObj | Where-Object { ($_.'Reporting Nodes').count -gt 2 } | Set-Style -Style Warning -Property 'Reporting Nodes'
                        }

                        $TableParams = @{
                            Name = "Igroup - $($Item.Name)"
                            List = $true
                            ColumnWidths = 25, 75
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $VserverObj | Table @TableParams
                        if ($Healthcheck.Vserver.Status -and ($VserverObj | Where-Object { ($_.'Reporting Nodes').count -gt 2 })) {
                            Paragraph "Health Check:" -Bold -Underline
                            BlankLine
                            Paragraph {
                                Text "Best Practice:" -Bold
                                Text "Ensure that igroups have an optimal number of reporting nodes to maintain performance and reliability."
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