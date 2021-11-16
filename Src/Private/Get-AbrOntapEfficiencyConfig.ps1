function Get-AbrOntapEfficiencyConfig {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP Storage Efficiency Savings information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.5.0
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
        Write-PscriboMessage "Collecting ONTAP Storage Efficiency Savings information."
    }

    process {
        $Data =  Get-NcAggr -Controller $Array | Where-Object {$_.AggrRaidAttributes.HasLocalRoot -ne 'True'}
        $OutObj = @()
        if ($Data) {
            foreach ($Item in $Data) {
                $Saving = Get-NcAggr -Aggregate $Item.Name -Controller $Array | Select-Object -ExpandProperty AggrSpaceAttributes
                $TotalStorageEfficiencyRatio = Get-NcAggrEfficiency -Aggregate $Item.Name -Controller $Array |  Select-Object -ExpandProperty AggrEfficiencyCumulativeInfo
                $inObj = [ordered] @{
                    'Aggregate' = $Item.Name
                    'Used %' = $Saving.PercentUsedCapacity | ConvertTo-FormattedNumber -Type Percent -ErrorAction SilentlyContinue
                    'Capacity Tier Used' = $Saving.CapacityTierUsed | ConvertTo-FormattedNumber -Type Datasize -NumberFormatString "0.0" -ErrorAction SilentlyContinue
                    'Compaction Saved %' = $Saving.DataCompactionSpaceSavedPercent | ConvertTo-FormattedNumber -Type Percent -ErrorAction SilentlyContinue
                    'Deduplication Saved %' = $Saving.SisSpaceSavedPercent | ConvertTo-FormattedNumber -Type Percent -ErrorAction SilentlyContinue
                    'Total Data Reduction' = $TotalStorageEfficiencyRatio.TotalStorageEfficiencyRatio

                }
                $OutObj += [pscustomobject]$inobj
            }

            $TableParams = @{
                Name = "Storage Efficiency Savings Information - $($ClusterInfo.ClusterName)"
                List = $false
                ColumnWidths = 30, 10, 15, 15, 15, 15
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $OutObj | Table @TableParams
        }
    }

    end {}

}