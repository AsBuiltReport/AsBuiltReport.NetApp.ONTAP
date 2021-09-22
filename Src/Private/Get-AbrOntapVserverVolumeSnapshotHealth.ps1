function Get-AbrOntapVserverVolumeSnapshotHealth {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP vserver volumes snapshot healthcheck information from the Cluster Management Network
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
        Write-PscriboMessage "Collecting ONTAP Vserver volumes snapshot healthcheck information."
    }

    process {
        $SnapshotDays = 7
        $Now=Get-Date
        $VserverFilter = Get-NcVol | Where-Object {$_.JunctionPath -ne '/' -and $_.Name -ne 'vol0'}
        $SnapShotData = get-ncsnapshot -Volume $VserverFilter | Where-Object {$_.Name -notmatch "snapmirror.*" -and $_.Created -le $Now.AddDays(-$SnapshotDays)}
        $VserverObj = @()
        if ($SnapShotData) {
            foreach ($Item in $SnapShotData) {
                $inObj = [ordered] @{
                    'Volume Name' = $Item.Volume
                    'Snapshot Name' = $Item.Name
                    'Created Time' = $Item.Created
                    'Used' = $Item.Total | ConvertTo-FormattedNumber -Type Datasize -ErrorAction SilentlyContinue
                    'Vserver' = $Item.Vserver
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

    end {}

}