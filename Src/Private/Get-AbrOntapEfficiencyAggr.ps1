function Get-AbrOntapEfficiencyAggr {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP Aggregate Efficiency Savings information from the Cluster Management Network
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
        Write-PscriboMessage "Collecting ONTAP Aggregate Efficiency Savings information."
    }

    process {
        $Data =  Get-NcAggr | Where-Object {$_.AggrRaidAttributes.HasLocalRoot -ne 'True'}
        $OutObj = @()
        if ($Data) {
            foreach ($Item in $Data) {
                $Saving = Get-NcAggrEfficiency -Aggregate $Item.Name | Select-Object -ExpandProperty AggrEfficiencyAggrInfo
                $inObj = [ordered] @{
                    'Aggregate' = $Item.Name
                    'Logical Used' = $Saving.AggrLogicalUsed | ConvertTo-FormattedNumber -Type Datasize -ErrorAction SilentlyContinue
                    'Physical Used' = $Saving.AggrPhysicalUsed | ConvertTo-FormattedNumber -Type Datasize -ErrorAction SilentlyContinue
                    'Compaction Saved' = $Saving.AggrCompactionSaved | ConvertTo-FormattedNumber -Type Datasize -ErrorAction SilentlyContinue
                    'Data reduction' = $Saving.AggrDataReductionStorageEfficiencyRatio

                }
                $OutObj += [pscustomobject]$inobj
            }

            $TableParams = @{
                Name = "Aggregate Efficiency Savings Information - $($ClusterInfo.ClusterName)"
                List = $false
                ColumnWidths = 35, 15, 15, 15, 20
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $OutObj | Table @TableParams
        }
        $Data =  Get-NcAggr | Where-Object {$_.AggrRaidAttributes.HasLocalRoot -ne 'True'}
        $Savingfilter = (Get-NcAggrEfficiency | Select-Object -ExpandProperty AggrEfficiencyAdditionalDetailsInfo).NumberOfSisDisabledVolumes | Measure-Object -Sum
        if ($Data -and $Savingfilter.Sum -gt 0 -and $Healthcheck.Storage.Efficiency) {
            Section -Style Heading4 'HealthCheck - Volume efficiency opportunities for improvement' {
                Paragraph "The following section provides the Volume efficiency healthcheck Information on $($ClusterInfo.ClusterName)."
                BlankLine
                $OutObj = @()
                foreach ($Item in $Data) {
                    $Saving = Get-NcAggrEfficiency -Aggregate $Item.Name | Select-Object -ExpandProperty AggrEfficiencyAdditionalDetailsInfo
                    $VolInAggr = Get-NcVol -Aggregate $Item.Name
                    $VolFilter = $VolInAggr | Where-Object { $_.VolumeSisAttributes.IsSisStateEnabled -ne "True"}
                    $inObj = [ordered] @{
                        'Aggregate' = $Item.Name
                        'Volumes without Deduplication' = $VolFilter.Name
                    }
                    $OutObj += [pscustomobject]$inobj
                }

                if ($Healthcheck.Storage.Efficiency) {
                    $OutObj | Set-Style -Style Warning -Property 'Aggregate','Volumes without Deduplication'
                }

                $TableParams = @{
                    Name = "HealthCheck - Volume efficiency opportunities for improvement - $($ClusterInfo.ClusterName)"
                    List = $false
                    ColumnWidths = 45, 55
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $OutObj | Table @TableParams
            }
        }
    }

    end {}

}