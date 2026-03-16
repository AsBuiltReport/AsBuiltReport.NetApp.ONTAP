function Get-AbrOntapVserverVolumesSpaceAttr {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP vserver per volumes space attributes information from the Cluster Management Network
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
        Write-PScriboMessage 'Collecting ONTAP Vserver per volumes space attributes information.'
    }

    process {
        try {
            $VolumeFilter = Get-NcVol -VserverContext $Vserver -Controller $Array | Where-Object { $_.JunctionPath -ne '/' -and $_.Name -ne 'vol0' }
            $OutObj = @()
            if ($VolumeFilter) {
                foreach ($Item in $VolumeFilter) {
                    try {
                        $SpaceAttr = $Item.VolumeSpaceAttributes
                        $inObj = [ordered] @{
                            'Volume' = $Item.Name
                            'Total Size' = ($SpaceAttr.Size | ConvertTo-FormattedNumber -ErrorAction SilentlyContinue -NumberFormatString 0.0 -Type Datasize) ?? '--'
                            'Available' = ($SpaceAttr.SizeAvailable | ConvertTo-FormattedNumber -ErrorAction SilentlyContinue -NumberFormatString 0.0 -Type Datasize) ?? '--'
                            'Used' = ($SpaceAttr.SizeUsed | ConvertTo-FormattedNumber -ErrorAction SilentlyContinue -NumberFormatString 0.0 -Type Datasize) ?? '--'
                            '% Used' = ($SpaceAttr.PercentageSizeUsed | ConvertTo-FormattedNumber -ErrorAction SilentlyContinue -Type Percent) ?? '--'
                            'Space Guarantee' = $SpaceAttr.SpaceGuarantee ?? '--'
                            'Guarantee Enabled' = $SpaceAttr.IsSpaceGuaranteeEnabled
                        }
                        $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }

                $TableParams = @{
                    Name = "Per Volume Space Attributes - $($Vserver)"
                    List = $false
                    ColumnWidths = 20, 12, 12, 12, 10, 18, 16
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
