function Get-AbrOntapEfficiencyConfig {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP Storage Efficiency Savings information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.6.12
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
        Write-PScriboMessage 'Collecting ONTAP Storage Efficiency Savings information.'
    }

    process {
        try {
            $Data = Get-NcAggr -Controller $Array | Where-Object { $_.AggrRaidAttributes.HasLocalRoot -ne 'True' }
            $OutObj = @()
            if ($Data) {
                foreach ($Item in $Data) {
                    try {
                        $Saving = Get-NcAggr -Aggregate $Item.Name -Controller $Array | Select-Object -ExpandProperty AggrSpaceAttributes
                        $TotalStorageEfficiencyRatio = Get-NcAggrEfficiency -Aggregate $Item.Name -Controller $Array | Select-Object -ExpandProperty AggrEfficiencyCumulativeInfo
                        $inObj = [ordered] @{
                            'Aggregate' = $Item.Name
                            'Used %' = ($Saving.PercentUsedCapacity | ConvertTo-FormattedNumber -Type Percent) ?? '--'
                            'Capacity Tier Used' = ($Saving.CapacityTierUsed | ConvertTo-FormattedNumber -NumberFormatString 0.0 -Type Datasize) ?? '--'
                            'Compaction Saved %' = ($Saving.DataCompactionSpaceSavedPercent | ConvertTo-FormattedNumber -Type Percent) ?? '--'
                            'Deduplication Saved %' = ($Saving.SisSpaceSavedPercent | ConvertTo-FormattedNumber -Type Percent) ?? '--'
                            'Total Data Reduction' = $TotalStorageEfficiencyRatio.TotalStorageEfficiencyRatio

                        }
                        $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }

                $TableParams = @{
                    Name = "Storage Efficiency Savings - $($ClusterInfo.ClusterName)"
                    List = $false
                    ColumnWidths = 30, 10, 15, 15, 15, 15
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $OutObj | Table @TableParams
            }
        } catch {
            Write-PScriboMessage -IsWarning $_.Exception.Message
        }
    }

    end {}

}