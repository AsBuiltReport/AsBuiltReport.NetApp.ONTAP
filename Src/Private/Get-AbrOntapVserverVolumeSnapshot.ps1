function Get-AbrOntapVserverVolumeSnapshot {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP vserver volumes snapshot information from the Cluster Management Network
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
        Write-PscriboMessage "Collecting ONTAP Vserver volumes snapshot information."
    }

    process {
        $VserverData = Get-NcVol | Where-Object {$_.JunctionPath -ne '/' -and $_.Name -ne 'vol0'}
        $VserverObj = @()
        if ($VserverData) {
            foreach ($Item in $VserverData) {
                $SnapReserve = Get-NcVol $Item.Name | Select-Object -ExpandProperty VolumeSpaceAttributes
                $SnapPolicy = Get-NcVol $Item.Name | Select-Object -ExpandProperty VolumeSnapshotAttributes
                if ($SnapPolicy.SnapshotCount -gt 0) {
                    $inObj = [ordered] @{
                        'Volume' = $Item.Name
                        'Reserve Size' = $SnapReserve.SnapshotReserveSize | ConvertTo-FormattedNumber -Type Datasize -ErrorAction SilentlyContinue
                        'Reserve Available' = $SnapReserve.SnapshotReserveAvailable | ConvertTo-FormattedNumber -Type Datasize -ErrorAction SilentlyContinue
                        'Used' = $SnapReserve.SizeUsedBySnapshots | ConvertTo-FormattedNumber -Type Datasize -ErrorAction SilentlyContinue
                        'Policy' = $SnapPolicy.SnapshotPolicy
                        'Vserver' = $Item.Vserver
                    }
                }

                $VserverObj += [pscustomobject]$inobj
            }

            $TableParams = @{
                Name = "Vserver Volume SnapShot Configuration Information - $($ClusterInfo.ClusterName)"
                List = $false
                ColumnWidths = 30, 12, 12, 15, 16, 15
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            if ($VserverObj) {
                $VserverObj | Table @TableParams
            }
        }
    }

    end {}

}