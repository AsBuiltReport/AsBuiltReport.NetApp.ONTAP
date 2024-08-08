function Get-AbrOntapVserverVolumeSnapshotHealth {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP vserver volumes snapshot healthcheck information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.6.7
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
        Write-PScriboMessage "Collecting ONTAP Vserver volumes snapshot healthcheck information."
    }

    process {
        try {
            $SnapshotDays = 7
            $Now = Get-Date
            $VserverFilter = Get-NcVol -VserverContext $Vserver -Controller $Array | Where-Object { $_.JunctionPath -ne '/' -and $_.Name -ne 'vol0' }
            $SnapShotData = Get-NcSnapshot -Volume $VserverFilter -Controller $Array | Where-Object { $_.Name -notmatch "snapmirror.*" -and $_.Created -le $Now.AddDays(-$SnapshotDays) }
            if ($SnapShotData) {
                Section -Style Heading4 "HealthCheck - Volumes Snapshot" {
                    Paragraph "The following section provides the Vserver Volumes Snapshot HealthCheck on $($SVM)."
                    BlankLine
                    $VserverObj = @()
                    foreach ($Item in $SnapShotData) {
                        try {
                            $inObj = [ordered] @{
                                'Volume Name' = $Item.Volume
                                'Snapshot Name' = $Item.Name
                                'Created Time' = $Item.Created
                                'Used' = $Item.Total | ConvertTo-FormattedNumber -Type Datasize -ErrorAction SilentlyContinue
                            }
                            $VserverObj += [pscustomobject]$inobj
                        } catch {
                            Write-PScriboMessage -IsWarning $_.Exception.Message
                        }
                    }

                    $TableParams = @{
                        Name = "HealthCheck - Volume Snapshot over 7 days - $($Vserver)"
                        List = $false
                        ColumnWidths = 25, 35, 25, 15
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }

                    $VserverObj | Table @TableParams
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning $_.Exception.Message
        }
    }

    end {}

}