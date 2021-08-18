function Get-AbrOntapVserverVolumeSnapshotHealth {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP vserver volumes snapshot healthcheck information from the Cluster Management Network
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
        Write-PscriboMessage "Collecting ONTAP Vserver volumes snapshot healthcheck information."
    }

    process {
        $SnapshotDays = 7
        $Now=Get-Date
        $VserverData = Get-NcVol | Where-Object {$_.JunctionPath -ne '/' -and $_.Name -ne 'vol0'}
        $VserverObj = @()
        if ($VserverData) {
            foreach ($Vol in $VserverData) {
                $SnapCount = Get-NcVol $Vol.Name | Select-Object -ExpandProperty VolumeSnapshotAttributes
                $Snap = get-ncsnapshot $Vol.Name | Select-Object Name,Total,Created
                foreach ($Item in $Snap) {
                    foreach ($Item in $Snap) {
                        if ($SnapCount.SnapshotCount -gt 0 -and $Item.Created -le $Now.AddDays(-$SnapshotDays) -and $Item.Name -notmatch "snapmirror.*") {
                            $inObj = [ordered] @{
                                'Volume Name' = $Vol.Name
                                'Snapshot Name' = $Item.Name
                                'Created Time' = $Item.Created
                                'Used' = $Item.Total | ConvertTo-FormattedNumber -Type Datasize -ErrorAction SilentlyContinue
                                'Vserver' = $Vol.Vserver
                            }
                        }
                        else {continue}
                    }
                }
                $VserverObj += [pscustomobject]$inobj
            }

            $VserverObjSorted = $VserverObj | Select-Object -Unique -Property 'Volume Name','Snapshot Name','Created Time','Used','Vserver'
            $TableParams = @{
                Name = "HealthCheck - Volume Snapshot over 7 days only - $($ClusterInfo.ClusterName)"
                List = $false
                ColumnWidths = 20, 30, 25, 10, 15
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $VserverObjSorted | Table @TableParams
        }
    }

    end {}

}