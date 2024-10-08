function Get-AbrOntapVserverVolumeSnapshot {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP vserver volumes snapshot information from the Cluster Management Network
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
        Write-PScriboMessage "Collecting ONTAP Vserver volumes snapshot information."
    }

    process {
        try {
            $VolumeFilter = Get-NcVol -VserverContext $Vserver -Controller $Array | Where-Object { $_.JunctionPath -ne '/' -and $_.Name -ne 'vol0' }
            $VserverObj = @()
            if ($VolumeFilter) {
                foreach ($Item in $VolumeFilter) {
                    try {
                        $SnapReserve = Get-NcVol $Item.Name -VserverContext $Vserver -Controller $Array | Select-Object -ExpandProperty VolumeSpaceAttributes
                        $SnapPolicy = Get-NcVol $Item.Name -VserverContext $Vserver -Controller $Array | Select-Object -ExpandProperty VolumeSnapshotAttributes
                        $inObj = [ordered] @{
                            'Volume' = $Item.Name
                            'Snapshot Enabled' = ConvertTo-TextYN $SnapPolicy.AutoSnapshotsEnabled
                            'Reserve Size' = $SnapReserve.SnapshotReserveSize | ConvertTo-FormattedNumber -Type Datasize -ErrorAction SilentlyContinue
                            'Reserve Available' = $SnapReserve.SnapshotReserveAvailable | ConvertTo-FormattedNumber -Type Datasize -ErrorAction SilentlyContinue
                            'Used' = $SnapReserve.SizeUsedBySnapshots | ConvertTo-FormattedNumber -Type Datasize -ErrorAction SilentlyContinue
                            'Policy' = $SnapPolicy.SnapshotPolicy
                        }

                        $VserverObj += [pscustomobject]$inobj
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }
                if ($Healthcheck.Vserver.Snapshot) {
                    $VserverObj | Where-Object { $_.'Snapshot Enabled' -eq 'True' -and $_.'Reserve Available' -eq 0 } | Set-Style -Style Warning -Property 'Reserve Size', 'Reserve Available', 'Used'
                }

                $TableParams = @{
                    Name = "Volume SnapShot Configuration - $($Vserver)"
                    List = $false
                    ColumnWidths = 25, 15, 15, 15, 15, 15
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                if ($VserverObj) {
                    $VserverObj | Table @TableParams
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning $_.Exception.Message
        }
    }

    end {}

}
