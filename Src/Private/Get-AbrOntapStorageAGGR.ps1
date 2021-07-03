function Get-AbrOntapStorageAGGR {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP storage summary information from the Cluster Management Network
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
        Write-PscriboMessage "Collecting ONTAP storage aggregate information."
    }

    process {
        $Unit = "GB"
        $AggrSpace = Get-NcAggr
        if ($AggrSpace) {
            $AggrSpaceSummary = foreach ($Aggr in $AggrSpace) {
            $RootAggr = Get-NcAggr $Aggr.Name | ForEach-Object{ $_.AggrRaidAttributes.HasLocalRoot }
                [PSCustomObject] @{
                    'Name' = $Aggr.Name
                    'Capacity' = "$([math]::Round(($Aggr.Totalsize) / "1$($Unit)", 2))$Unit"
                    'Available' = "$([math]::Round(($Aggr.Available) / "1$($Unit)", 2))$Unit"
                    'Used %' = [int]$Aggr.Used
                    'Disk Count' = $Aggr.Disks
                    'Root' = $RootAggr
                    'Raid Type' = ($Aggr.RaidType.Split(",")[0]).ToUpper()
                    'State' = $Aggr.State
                }
            }
            if ($Healthcheck.Storage.Aggr) {
                $AggrSpaceSummary | Where-Object { $_.'State' -eq 'failed' } | Set-Style -Style Critical -Property 'State'
                $AggrSpaceSummary | Where-Object { $_.'State' -eq 'unknown' -or $_.'State' -eq 'offline' } | Set-Style -Style Warning -Property 'State'
                $AggrSpaceSummary | Where-Object { $_.'Used %' -ge 90 } | Set-Style -Style Critical -Property 'Used %'
            }
            $TableParams = @{
                Name = "Aggregate Summary - $($ClusterInfo.ClusterName)"
                List = $false
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $AggrSpaceSummary | Table @TableParams
        }
    }

    end {}

}