function Get-AbrOntapEfficiencyVol {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP Volume Efficiency Savings information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.6.12
        Author:         Jonathan Colon
        Twitter:        @jcolonfzenpr
        Github:         rebelinux
    .EXAMPLE

    .LINK

    #>
    param (
        [Parameter (
            Position = 0,
            Mandatory)]
        [string]
        $Vserver
    )

    begin {
        Write-PScriboMessage 'Collecting ONTAP Volume Efficiency Savings information.'
    }

    process {
        try {
            $Data = Get-NcVol -VserverContext $Vserver -Controller $Array | Where-Object { $_.JunctionPath -ne '/' -and $_.Name -ne 'vol0' -and $_.State -eq 'online' }
            $OutObj = @()
            if ($Data) {
                foreach ($Item in $Data) {
                    try {
                        $Saving = Get-NcEfficiency -Volume $Item.Name -Vserver $Vserver -Controller $Array
                        $inObj = [ordered] @{
                            'Volume' = $Item.Name
                            'Capacity' = ($Saving.Capacity | ConvertTo-FormattedNumber -NumberFormatString 0.0 -Type Datasize) ?? '--'
                            'Used' = ($Saving.Used | ConvertTo-FormattedNumber -NumberFormatString 0.0 -Type Datasize) ?? '--'
                            'Snapshot Used' = ($Saving.SnapshotUsed | ConvertTo-FormattedNumber -NumberFormatString 0.0 -Type Datasize) ?? '--'
                            'Total Savings' = ($Saving.Returns.Total | ConvertTo-FormattedNumber -NumberFormatString 0.0 -Type Datasize) ?? '--'
                            'Effective Used' = ($Saving.EffectiveUsed | ConvertTo-FormattedNumber -NumberFormatString 0.0 -Type Datasize) ?? '--'
                            'Efficiency Percent' = ($Saving.EfficiencyPercent | ConvertTo-FormattedNumber -Type Percent -NumberFormatString 0.0) ?? '--'
                        }
                        $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }

                $TableParams = @{
                    Name = "Volume Efficiency Savings - $($Vserver)"
                    List = $false
                    ColumnWidths = 30, 15, 10, 11, 10, 12 , 12
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
