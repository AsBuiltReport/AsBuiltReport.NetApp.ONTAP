function Get-AbrOntapEfficiencyVol {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP Volume Efficiency Savings information from the Cluster Management Network
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
        Write-PscriboMessage "Collecting ONTAP Volume Efficiency Savings information."
    }

    process {
        $Data =  Get-NcVol | Where-Object {$_.Name -ne 'vol0'}
        $OutObj = @()
        if ($Data) {
            foreach ($Item in $Data) {
                $Saving = Get-NcEfficiency -Volume $Item.Name
                $inObj = [ordered] @{
                    'Volume' = $Item.Name
                    'Capacity' = $Saving.Capacity | ConvertTo-FormattedNumber -Type Datasize -ErrorAction SilentlyContinue
                    'Used' = $Saving.Used | ConvertTo-FormattedNumber -Type Datasize -ErrorAction SilentlyContinue
                    'Snapshot Used' = $Saving.SnapshotUsed | ConvertTo-FormattedNumber -Type Datasize -ErrorAction SilentlyContinue
                    'Total Savings' = $Saving.Returns.Total | ConvertTo-FormattedNumber -Type Datasize -ErrorAction SilentlyContinue
                    'Effective Used' = $Saving.EffectiveUsed | ConvertTo-FormattedNumber -Type Datasize -ErrorAction SilentlyContinue
                    'Efficiency Percent' = $Saving.EfficiencyPercent | ConvertTo-FormattedNumber -Type Percent -NumberFormatString "0.0" -ErrorAction SilentlyContinue
                }
                $OutObj += [pscustomobject]$inobj
            }

            $TableParams = @{
                Name = "Volume Efficiency Savings Information - $($ClusterInfo.ClusterName)"
                List = $false
                ColumnWidths = 30, 15, 10, 11, 10, 12 ,12
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $OutObj | Table @TableParams
        }
    }

    end {}

}