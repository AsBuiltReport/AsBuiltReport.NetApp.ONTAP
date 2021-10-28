function Get-AbrOntapVserverSummary {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP Vserver information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.5.0
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
        Write-PscriboMessage "Collecting ONTAP Vserver information."
    }

    process {
        $VserverData = Get-NcVserver -VserverContext $Vserver| Where-Object { $_.VserverType -eq "data" }
        $VserverObj = @()
        if ($VserverData) {
            foreach ($Item in $VserverData) {
                $inObj = [ordered] @{
                    'Vserver Type' = $Item.VserverType
                    'Allowed Protocols' = [string]$Item.AllowedProtocols
                    'Disallowed Protocols' = [string]$Item.DisallowedProtocols
                    'IP Space' = $Item.Ipspace
                    'Status' = $Item.State
                }
                $VserverObj += [pscustomobject]$inobj
            }
            if ($Healthcheck.Vserver.Status) {
                $VserverObj | Where-Object { $_.'Status' -like 'stopped' } | Set-Style -Style Warning -Property 'Status'
            }

            $TableParams = @{
                Name = "Vserver Information - $($Vserver)"
                List = $false
                ColumnWidths = 20, 20, 20, 20, 20
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $VserverObj | Table @TableParams
        }
        Section -Style Heading4 'Root Volume' {
            Paragraph "The following section provides the Vserver Root Volume Information on $($Vserver)."
            BlankLine
            $VserverRootVol = Get-NcVol -VserverContext $Vserver| Where-Object {$_.JunctionPath -eq '/'}
            $VserverObj = @()
            if ($VserverRootVol) {
                foreach ($Item in $VserverRootVol) {
                    $inObj = [ordered] @{
                        'Root Volume' = $Item.Name
                        'Status' = $Item.State
                        'TotalSize' = $Item.Totalsize | ConvertTo-FormattedNumber -Type Datasize -ErrorAction SilentlyContinue
                        'Used' = $Item.Used | ConvertTo-FormattedNumber -Type Percent -ErrorAction SilentlyContinue
                        'Available' = $Item.Available | ConvertTo-FormattedNumber -Type Datasize -ErrorAction SilentlyContinue
                        'Dedup' = ConvertTo-TextYN $Item.Dedupe
                        'Aggregate' = $Item.Aggregate
                    }
                    $VserverObj += [pscustomobject]$inobj
                }
                if ($Healthcheck.Vserver.Status) {
                    $VserverObj | Where-Object { $_.'Status' -like 'offline' } | Set-Style -Style Warning -Property 'Status'
                }

                $TableParams = @{
                    Name = "Vserver Root Volume Information - $($Vserver)"
                    List = $false
                    ColumnWidths = 20, 10, 10, 10, 10, 10, 30
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $VserverObj | Table @TableParams
            }
        }
        if (Get-NcVserverAggr) {
            Section -Style Heading4 'Aggregate Resource Allocation' {
                Paragraph "The following section provides the Vserver Aggregate Resource Allocation Information on $($Vserver)."
                BlankLine
                $VserverAGGR = Get-NcVserverAggr -VserverContext $Vserver -Controller $Array
                $VserverObj = @()
                if ($VserverAGGR) {
                    foreach ($Item in $VserverAGGR) {
                        $inObj = [ordered] @{
                            'Aggregate' = $Item.AggregateName
                            'Type' = $Item.AggregateType
                            'SnapLock Type' = $Item.SnaplockType
                            'Available' = $Item.AvailableSize | ConvertTo-FormattedNumber -Type Datasize -ErrorAction SilentlyContinue
                        }
                        $VserverObj += [pscustomobject]$inobj
                    }

                    $TableParams = @{
                        Name = "Vserver Aggregate Resource Allocation Information - $($Vserver)"
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
    }

    end {}

}