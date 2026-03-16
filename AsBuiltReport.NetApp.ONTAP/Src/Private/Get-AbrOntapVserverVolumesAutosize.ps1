function Get-AbrOntapVserverVolumesAutosize {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP vserver per volumes autosize attributes information from the Cluster Management Network
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
        Write-PScriboMessage 'Collecting ONTAP Vserver per volumes autosize attributes information.'
    }

    process {
        try {
            $VolumeFilter = Get-NcVol -VserverContext $Vserver -Controller $Array | Where-Object { $_.JunctionPath -ne '/' -and $_.Name -ne 'vol0' }
            $OutObj = @()
            if ($VolumeFilter) {
                foreach ($Item in $VolumeFilter) {
                    try {
                        $AutosizeAttr = $Item.VolumeAutosizeAttributes
                        $inObj = [ordered] @{
                            'Volume' = $Item.Name
                            'Autosize Enabled' = $AutosizeAttr.IsEnabled
                            'Mode' = $AutosizeAttr.Mode ?? '--'
                            'Minimum Size' = ($AutosizeAttr.MinimumSize | ConvertTo-FormattedNumber -ErrorAction SilentlyContinue -NumberFormatString 0.0 -Type Datasize) ?? '--'
                            'Maximum Size' = ($AutosizeAttr.MaximumSize | ConvertTo-FormattedNumber -ErrorAction SilentlyContinue -NumberFormatString 0.0 -Type Datasize) ?? '--'
                            'Grow Threshold %' = ($AutosizeAttr.GrowThresholdPercent | ConvertTo-FormattedNumber -ErrorAction SilentlyContinue -Type Percent) ?? '--'
                            'Shrink Threshold %' = ($AutosizeAttr.ShrinkThresholdPercent | ConvertTo-FormattedNumber -ErrorAction SilentlyContinue -Type Percent) ?? '--'
                        }
                        $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }

                $TableParams = @{
                    Name = "Per Volume Autosize Attributes - $($Vserver)"
                    List = $false
                    ColumnWidths = 20, 14, 10, 14, 14, 14, 14
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
