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
        $Unit = "GB"
        $VserverData = Get-NcVol | Where-Object {$_.JunctionPath -ne '/' -and $_.Name -ne 'vol0'}
        $VserverObj = @()
        if ($VserverData) {
            foreach ($Item in $VserverData) {
                $SnapPolicy = Get-NcVol $Item.Name | Select-Object -ExpandProperty VolumeSnapshotAttributes
                $SnapUsed = (Get-NcVol $Item.Name | Get-NCSnapshot | Select-Object -ExpandProperty Total | Measure-Object -Sum).sum
                if ($SnapPolicy.SnapshotCount -gt 0) {
                    $inObj = [ordered] @{
                        'Volume' = $Item.Name
                        'Snapshot Count' = $SnapPolicy.SnapshotCount
                        'Snapshot Policy' = $SnapPolicy.SnapshotPolicy
                        'Used' = "$([math]::Round(($SnapUsed) / "1$($Unit)", 3))$Unit"
                        'Vserver' = $Item.Vserver
                    }
                }
                else {
                    continue
                }
                $VserverObj += [pscustomobject]$inobj
            }

            $TableParams = @{
                Name = "Vserver Volume SnapShot Configuration Information - $($ClusterInfo.ClusterName)"
                List = $false
                ColumnWidths = 40, 15, 15, 15, 15
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $VserverObj | Table @TableParams
        }
        if ($Healthcheck.Vserver.Snapshot) {
            $Unit = "GB"
            $SnapshotDays = 7
            $Now=Get-Date
            $VserverData = Get-NcVol | Where-Object {$_.JunctionPath -ne '/' -and $_.Name -ne 'vol0'}
            $VserverObj = @()
            if ($VserverData) {
                foreach ($Vol in $VserverData) {
                    $SnapCount = (Get-NcVol $Vol.Name | Select-Object -ExpandProperty VolumeSnapshotAttributes).SnapshotCount
                    $Snap = get-ncsnapshot $Vol.Name | Select-Object Name,Total,Created,Busy
                    foreach ($Item in $Snap) {
                        if ($SnapCount -gt 0 -and $Item.Created -le $Now.AddDays(-$SnapshotDays) -and $Item.Name -notlike '*snapmirror*') {
                            $inObj = [ordered] @{
                                'Volume Name' = $Vol.Name
                                'Snapshot Name' = $Item.Name
                                'Created Time' = $Item.Created
                                'Used' = "$([math]::Round(($Item.Total) / "1$($Unit)", 3))$Unit"
                                'Vserver' = $Vol.Vserver
                            }
                        }
                        else {
                            continue
                        }
                    }
                    $VserverObj += [pscustomobject]$inobj
                }

                $TableParams = @{
                    Name = "HealthCheck - Volume Snapshot over 7 days only - $($ClusterInfo.ClusterName)"
                    List = $false
                    ColumnWidths = 20, 30, 25, 10, 15
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $VserverObj | Table @TableParams
            }
        }
    }

    end {}

}