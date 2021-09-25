function Get-AbrOntapEfficiencyVolDetailed {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP Volume Efficiency Savings information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.4.0
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
        $Data =  Get-NcVol | Where-Object {$_.JunctionPath -ne '/' -and $_.Name -ne 'vol0' -and $_.State -eq "online"}
        $OutObj = @()
        if ($Data) {
            foreach ($Item in $Data) {
                $Saving = Get-NcEfficiency -Volume $Item.Name
                $inObj = [ordered] @{
                    'Volume' = $Item.Name
                    'Capacity' = $Saving.Capacity | ConvertTo-FormattedNumber -Type Datasize -ErrorAction SilentlyContinue
                    'Dedupe Savings' = $Saving.Returns.Dedupe | ConvertTo-FormattedNumber -Type Datasize -ErrorAction SilentlyContinue
                    'Compression Savings' = $Saving.Returns.Compression | ConvertTo-FormattedNumber -Type Datasize -ErrorAction SilentlyContinue
                    'Snapshot Savings' = $Saving.Returns.Snapshot | ConvertTo-FormattedNumber -Type Datasize -ErrorAction SilentlyContinue
                    'Cloning Savings' = $Saving.Returns.Cloning | ConvertTo-FormattedNumber -Type Datasize -ErrorAction SilentlyContinue
                    'Efficiency %' = $Saving.EfficiencyPercent | ConvertTo-FormattedNumber -Type Percent -NumberFormatString "0.0" -ErrorAction SilentlyContinue
                    'Efficiency % w/o Snapshots' = [Math]::Round((($Saving.Returns.Dedupe + $Saving.Returns.Compression) / ($Saving.Used  + $Saving.Returns.Dedupe + $Saving.Returns.Compression)) * 100) | ConvertTo-FormattedNumber -Type Percent -NumberFormatString "0.0" -ErrorAction SilentlyContinue
                }
                $OutObj += [pscustomobject]$inobj
            }

            $TableParams = @{
                Name = "Volume Efficiency Savings Detailed Information - $($ClusterInfo.ClusterName)"
                List = $false
                ColumnWidths = 20, 10, 10, 11, 10, 12, 12, 15
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $OutObj | Table @TableParams
        }
    }

    end {}

}