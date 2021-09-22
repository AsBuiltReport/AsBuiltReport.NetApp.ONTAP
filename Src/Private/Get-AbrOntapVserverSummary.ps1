function Get-AbrOntapVserverSummary {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP Vserver information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.3.0
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
        Write-PscriboMessage "Collecting ONTAP Vserver information."
    }

    process {
        $VserverData = Get-NcVserver | Where-Object { $_.VserverType -eq "data" }
        $VserverObj = @()
        if ($VserverData) {
            foreach ($Item in $VserverData) {
                $inObj = [ordered] @{
                    'Vserver Name' = $Item.Vserver
                    'Status' = $Item.State
                    'Vserver Type' = $Item.VserverType
                    'Allowed Protocols' = [string]$Item.AllowedProtocols
                    'Disallowed Protocols' = [string]$Item.DisallowedProtocols
                    'IP Space' = $Item.Ipspace
                }
                $VserverObj += [pscustomobject]$inobj
            }
            if ($Healthcheck.Vserver.Status) {
                $VserverObj | Where-Object { $_.'Status' -like 'stopped' } | Set-Style -Style Warning -Property 'Status'
            }

            $TableParams = @{
                Name = "Vserver Summary Information - $($ClusterInfo.ClusterName)"
                List = $false
                ColumnWidths = 15, 15, 15, 20, 20, 15
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $VserverObj | Table @TableParams
        }
        Section -Style Heading4 'Vserver Root Volume Summary' {
            Paragraph "The following section provides the Vserver Root Volume Information on $($ClusterInfo.ClusterName)."
            BlankLine
            $VserverRootVol = Get-NcVol | Where-Object {$_.JunctionPath -eq '/'}
            $VserverObj = @()
            if ($VserverRootVol) {
                foreach ($Item in $VserverRootVol) {
                    $inObj = [ordered] @{
                        'Root Volume' = $Item.Name
                        'Vserver' = $Item.Vserver
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
                    Name = "Vserver Root Volume Information - $($ClusterInfo.ClusterName)"
                    List = $false
                    ColumnWidths = 15, 15, 10, 10, 10, 10, 10, 20
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $VserverObj | Table @TableParams
            }
        }
        if (Get-NcVserverAggr) {
            Section -Style Heading4 'Vserver Aggregate Resource Allocation Summary' {
                Paragraph "The following section provides the Vserver Aggregate Resource Allocation Information on $($ClusterInfo.ClusterName)."
                BlankLine
                $VserverAGGR = Get-NcVserverAggr
                $VserverObj = @()
                if ($VserverAGGR) {
                    foreach ($Item in $VserverAGGR) {
                        $inObj = [ordered] @{
                            'Vserver' = $Item.VserverName
                            'Aggregate' = $Item.AggregateName
                            'Type' = $Item.AggregateType
                            'SnapLock Type' = $Item.SnaplockType
                            'Available' = $Item.AvailableSize | ConvertTo-FormattedNumber -Type Datasize -ErrorAction SilentlyContinue
                        }
                        $VserverObj += [pscustomobject]$inobj
                    }

                    $TableParams = @{
                        Name = "Vserver Aggregate Resource Allocation Information - $($ClusterInfo.ClusterName)"
                        List = $false
                        ColumnWidths = 25, 30, 10, 20, 15
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