function Get-AbrOntapEfficiencyVolDetailed {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP Volume Efficiency Savings information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.6.8
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
        Write-PScriboMessage "Collecting ONTAP Volume Efficiency Savings information."
    }

    process {
        try {
            $Data = Get-NcVol -VserverContext $Vserver -Controller $Array | Where-Object { $_.JunctionPath -ne '/' -and $_.Name -ne 'vol0' -and $_.State -eq "online" }
            $OutObj = @()
            if ($Data) {
                foreach ($Item in $Data) {
                    try {
                        $Saving = Get-NcEfficiency -Volume $Item.Name -Vserver $Vserver -Controller $Array
                        $inObj = [ordered] @{
                            'Volume' = $Item.Name
                            'Capacity' = $Saving.Capacity | ConvertTo-FormattedNumber -Type Datasize -ErrorAction SilentlyContinue
                            'Dedupe Savings' = $Saving.Returns.Dedupe | ConvertTo-FormattedNumber -Type Datasize -ErrorAction SilentlyContinue
                            'Compression Savings' = $Saving.Returns.Compression | ConvertTo-FormattedNumber -Type Datasize -ErrorAction SilentlyContinue
                            'Snapshot Savings' = $Saving.Returns.Snapshot | ConvertTo-FormattedNumber -Type Datasize -ErrorAction SilentlyContinue
                            'Cloning Savings' = $Saving.Returns.Cloning | ConvertTo-FormattedNumber -Type Datasize -ErrorAction SilentlyContinue
                            'Efficiency %' = $Saving.EfficiencyPercent | ConvertTo-FormattedNumber -Type Percent -NumberFormatString "0.0" -ErrorAction SilentlyContinue
                            'Efficiency % w/o Snapshots' = [Math]::Round((($Saving.Returns.Dedupe + $Saving.Returns.Compression) / ($Saving.Used + $Saving.Returns.Dedupe + $Saving.Returns.Compression)) * 100) | ConvertTo-FormattedNumber -Type Percent -NumberFormatString "0.0" -ErrorAction SilentlyContinue
                        }
                        $OutObj += [pscustomobject]$inobj
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }

                $TableParams = @{
                    Name = "Volume Efficiency Savings Detailed - $($Vserver)"
                    List = $false
                    ColumnWidths = 20, 10, 10, 11, 10, 12, 12, 15
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