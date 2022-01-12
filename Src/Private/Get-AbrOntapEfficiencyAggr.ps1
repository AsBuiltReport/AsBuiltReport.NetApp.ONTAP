function Get-AbrOntapEfficiencyAggr {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP Aggregate Efficiency Savings information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.6.2
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
        $Data =  Get-NcAggr -Controller $Array | Where-Object {$_.AggrRaidAttributes.HasLocalRoot -ne 'True'}
        $OutObj = @()
        if ($Data) {
            foreach ($Item in $Data) {
                $Saving = Get-NcAggrEfficiency -Aggregate $Item.Name -Controller $Array | Select-Object -ExpandProperty AggrEfficiencyAggrInfo
                $inObj = [ordered] @{
                    'Aggregate' = $Item.Name
                    'Logical Used' = $Saving.AggrLogicalUsed | ConvertTo-FormattedNumber -Type Datasize -ErrorAction SilentlyContinue
                    'Physical Used' = $Saving.AggrPhysicalUsed | ConvertTo-FormattedNumber -Type Datasize -ErrorAction SilentlyContinue
                    'Compaction Saved' = $Saving.AggrCompactionSaved | ConvertTo-FormattedNumber -Type Datasize -ErrorAction SilentlyContinue
                    'Data Reduction' = $Saving.AggrDataReductionStorageEfficiencyRatio

                }
                $OutObj += [pscustomobject]$inobj
            }

            $TableParams = @{
                Name = "Aggregate Efficiency Savings - $($ClusterInfo.ClusterName)"
                List = $false
                ColumnWidths = 35, 15, 15, 15, 20
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $OutObj | Table @TableParams
        }
        $Data =  Get-NcAggr -Controller $Array | Where-Object {$_.AggrRaidAttributes.HasLocalRoot -ne 'True'}
        $Savingfilter = (Get-NcAggrEfficiency -Controller $Array | Select-Object -ExpandProperty AggrEfficiencyAdditionalDetailsInfo).NumberOfSisDisabledVolumes | Measure-Object -Sum
        if ($Data -and $Savingfilter.Sum -gt 0 -and $Healthcheck.Storage.Efficiency) {
            Section -Style Heading4 'HealthCheck - Volume with Disabled Deduplication' {
                Paragraph "The following section provides the Volume efficiency healthcheck Information on $($ClusterInfo.ClusterName)."
                BlankLine
                $OutObj = @()
                foreach ($Item in $Data) {
                    $Saving = Get-NcAggrEfficiency -Aggregate $Item.Name -Controller $Array | Select-Object -ExpandProperty AggrEfficiencyAdditionalDetailsInfo
                    $VolInAggr = Get-NcVol -Aggregate $Item.Name -Controller $Array
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
                    Name = "HealthCheck - Volume without deduplication - $($ClusterInfo.ClusterName)"
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