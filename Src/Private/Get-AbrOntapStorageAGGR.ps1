function Get-AbrOntapStorageAGGR {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP storage summary information from the Cluster Management Network
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
        Write-PscriboMessage "Collecting ONTAP storage aggregate information."
    }

    process {
        $AggrSpace = Get-NcAggr
        if ($AggrSpace) {
            $AggrSpaceSummary = foreach ($Aggr in $AggrSpace) {
            $RootAggr = Get-NcAggr $Aggr.Name | ForEach-Object{ $_.AggrRaidAttributes.HasLocalRoot }
                [PSCustomObject] @{
                    'Name' = $Aggr.Name
                    'Capacity' = $Aggr.Totalsize | ConvertTo-FormattedNumber -Type Datasize -ErrorAction SilentlyContinue
                    'Available' = $Aggr.Available | ConvertTo-FormattedNumber -Type Datasize -ErrorAction SilentlyContinue
                    'Used' = $Aggr.Used | ConvertTo-FormattedNumber -Type Percent -ErrorAction SilentlyContinue
                    'Disk Count' = $Aggr.Disks
                    'Root' = ConvertTo-TextYN $RootAggr
                    'Raid Type' = ($Aggr.RaidType.Split(",")[0]).ToUpper()
                    'State' = $Aggr.State
                }
            }
            if ($Healthcheck.Storage.Aggr) {
                $AggrSpaceSummary | Where-Object { $_.'State' -eq 'failed' } | Set-Style -Style Critical -Property 'State'
                $AggrSpaceSummary | Where-Object { $_.'State' -eq 'unknown' -or $_.'State' -eq 'offline' } | Set-Style -Style Warning -Property 'State'
                $AggrSpaceSummary | Where-Object { $_.'Used' -ge 90 } | Set-Style -Style Critical -Property 'Used'
            }
            $TableParams = @{
                Name = "Aggregate Summary - $($ClusterInfo.ClusterName)"
                List = $false
                ColumnWidths = 27, 10, 10, 10, 10, 8, 15, 10
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $AggrSpaceSummary | Table @TableParams
        }
    }

    end {}

}