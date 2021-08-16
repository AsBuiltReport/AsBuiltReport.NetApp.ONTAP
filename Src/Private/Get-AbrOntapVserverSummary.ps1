function Get-AbrOntapVserverSummary {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP Vserver information from the Cluster Management Network
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
        Write-PscriboMessage "Collecting ONTAP Vserver information."
    }

    process {
        $Unit = "GB"
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
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $VserverObj | Table @TableParams
        }
        $VserverRootVol = Get-NcVol | Where-Object {$_.JunctionPath -eq '/'}
        $VserverObj = @()
        if ($VserverRootVol) {
            foreach ($Item in $VserverRootVol) {
                $inObj = [ordered] @{
                    'Root Volume' = $Item.Name
                    'Vserver' = $Item.Vserver
                    'Status' = $Item.State
                    'TotalSize' = "$([math]::Round(($Item.Totalsize) / "1$($Unit)", 2))$Unit" #// TODO convert to ConvertTo-FormattedNumber
                    'Used' = "$($Item.Used)%" #// TODO convert to ConvertTo-FormattedNumber
                    'Available' = "$([math]::Round(($Item.Available) / "1$($Unit)", 2))$Unit" #// TODO convert to ConvertTo-FormattedNumber
                    'Dedup' = $Item.Dedupe
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
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $VserverObj | Table @TableParams
        }
        $VserverAGGR = Get-NcVserverAggr
        $VserverObj = @()
        if ($VserverAGGR) {
            foreach ($Item in $VserverAGGR) {
                $inObj = [ordered] @{
                    'Vserver' = $Item.VserverName
                    'Aggregate' = $Item.AggregateName
                    'Type' = $Item.AggregateType
                    'SnapLock Type' = $Item.SnaplockType
                    'Available' = "$([math]::Round(($Item.AvailableSize) / "1$($Unit)", 2))$Unit" #// TODO convert to ConvertTo-FormattedNumber
                }
                $VserverObj += [pscustomobject]$inobj
            }

            $TableParams = @{
                Name = "Vserver Aggregate Resource Allocation Information - $($ClusterInfo.ClusterName)"
                List = $false
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $VserverObj | Table @TableParams
        }
    }

    end {}

}