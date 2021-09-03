function Get-AbrOntapVserverVolumeSnapshot {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP vserver volumes snapshot information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.3.0
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
        $VolumeFilter = Get-NcVol | Where-Object {$_.JunctionPath -ne '/' -and $_.Name -ne 'vol0'}
        $VserverObj = @()
        if ($VolumeFilter) {
            foreach ($Item in $VolumeFilter) {
                $SnapReserve = Get-NcVol $Item.Name | Select-Object -ExpandProperty VolumeSpaceAttributes
                $SnapPolicy = Get-NcVol $Item.Name | Select-Object -ExpandProperty VolumeSnapshotAttributes
                $inObj = [ordered] @{
                    'Volume' = $Item.Name
                    'Snapshot Enabled' = $SnapPolicy.AutoSnapshotsEnabled
                    'Reserve Size' = $SnapReserve.SnapshotReserveSize | ConvertTo-FormattedNumber -Type Datasize -ErrorAction SilentlyContinue
                    'Reserve Available' = $SnapReserve.SnapshotReserveAvailable | ConvertTo-FormattedNumber -Type Datasize -ErrorAction SilentlyContinue
                    'Used' = $SnapReserve.SizeUsedBySnapshots | ConvertTo-FormattedNumber -Type Datasize -ErrorAction SilentlyContinue
                    'Policy' = $SnapPolicy.SnapshotPolicy
                    'Vserver' = $Item.Vserver
                }

                $VserverObj += [pscustomobject]$inobj
            }
            if ($Healthcheck.Vserver.Snapshot) {
                $VserverObj | Where-Object { $_.'Snapshot Enabled' -eq 'True' -and $_.'Reserve Available' -eq 0 } | Set-Style -Style Warning -Property 'Reserve Size','Reserve Available','Used'
            }

            $TableParams = @{
                Name = "Vserver Volume SnapShot Configuration Information - $($ClusterInfo.ClusterName)"
                List = $false
                ColumnWidths = 20, 14, 12, 12, 12, 15, 15
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