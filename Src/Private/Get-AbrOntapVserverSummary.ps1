function Get-AbrOntapVserverSummary {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP Vserver information from the Cluster Management Network
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
        Write-PScriboMessage "Collecting ONTAP Vserver information."
    }

    process {
        try {
            $VserverData = Get-NcVserver -VserverContext $Vserver | Where-Object { $_.VserverType -eq "data" }
            $VserverObj = @()
            if ($VserverData) {
                foreach ($Item in $VserverData) {
                    try {
                        $inObj = [ordered] @{
                            'Vserver Type' = $Item.VserverType
                            'Allowed Protocols' = [string]$Item.AllowedProtocols
                            'Disallowed Protocols' = [string]$Item.DisallowedProtocols
                            'IPSpace' = $Item.Ipspace
                            'Status' = $Item.State
                        }
                        $VserverObj += [pscustomobject]$inobj
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }
                if ($Healthcheck.Vserver.Status) {
                    $VserverObj | Where-Object { $_.'Status' -like 'stopped' } | Set-Style -Style Warning -Property 'Status'
                }

                $TableParams = @{
                    Name = "Information - $($Vserver)"
                    List = $false
                    ColumnWidths = 20, 20, 20, 20, 20
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $VserverObj | Table @TableParams
                if ($Healthcheck.Vserver.Status -and ($VserverObj | Where-Object { $_.'Status' -like 'stopped' })) {
                    Paragraph "Health Check:" -Bold -Underline
                    BlankLine
                    Paragraph {
                        Text "Best Practice:" -Bold
                        Text "Ensure all Vservers are in 'running' status to provide uninterrupted services."
                    }
                    BlankLine
                }
            }
            try {
                Section -Style Heading4 'Root Volume' {
                    $VserverRootVol = Get-NcVol -VserverContext $Vserver | Where-Object { $_.JunctionPath -eq '/' }
                    $VserverObj = @()
                    if ($VserverRootVol) {
                        foreach ($Item in $VserverRootVol) {
                            try {
                                $inObj = [ordered] @{
                                    'Root Volume' = $Item.Name
                                    'Status' = $Item.State
                                    'Total Size' = $Item.Totalsize | ConvertTo-FormattedNumber -Type Datasize -ErrorAction SilentlyContinue
                                    'Used' = $Item.Used | ConvertTo-FormattedNumber -Type Percent -ErrorAction SilentlyContinue
                                    'Available' = $Item.Available | ConvertTo-FormattedNumber -Type Datasize -ErrorAction SilentlyContinue
                                    'Dedup' = ConvertTo-TextYN $Item.Dedupe
                                    'Aggregate' = $Item.Aggregate
                                }
                                $VserverObj += [pscustomobject]$inobj
                            } catch {
                                Write-PScriboMessage -IsWarning $_.Exception.Message
                            }
                        }
                        if ($Healthcheck.Vserver.Status) {
                            $VserverObj | Where-Object { $_.'Used' -ge 75 } | Set-Style -Style Warning -Property 'Used'
                            $VserverObj | Where-Object { $_.'Status' -like 'offline' } | Set-Style -Style Warning -Property 'Status'
                        }

                        $TableParams = @{
                            Name = "Root Volume - $($Vserver)"
                            List = $false
                            ColumnWidths = 20, 10, 10, 10, 10, 10, 30
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $VserverObj | Table @TableParams
                    }
                }
            } catch {
                Write-PScriboMessage -IsWarning $_.Exception.Message
            }
            try {
                if (Get-NcVserverAggr) {
                    Section -Style Heading4 'Aggregate Resource Allocation' {
                        $VserverAGGR = Get-NcVserverAggr -VserverContext $Vserver -Controller $Array
                        $VserverObj = @()
                        if ($VserverAGGR) {
                            foreach ($Item in $VserverAGGR) {
                                try {
                                    $inObj = [ordered] @{
                                        'Aggregate' = $Item.AggregateName
                                        'Type' = $Item.AggregateType
                                        'SnapLock Type' = $Item.SnaplockType
                                        'Available' = $Item.AvailableSize | ConvertTo-FormattedNumber -Type Datasize -ErrorAction SilentlyContinue
                                    }
                                    $VserverObj += [pscustomobject]$inobj
                                } catch {
                                    Write-PScriboMessage -IsWarning $_.Exception.Message
                                }
                            }

                            $TableParams = @{
                                Name = "Aggregate Resource Allocation - $($Vserver)"
                                List = $false
                                ColumnWidths = 40, 15, 25, 20
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $VserverObj | Table @TableParams
                        }
                    }
                }
            } catch {
                Write-PScriboMessage -IsWarning $_.Exception.Message
            }
        } catch {
            Write-PScriboMessage -IsWarning $_.Exception.Message
        }
    }

    end {}

}