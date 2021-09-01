function Get-AbrOntapSecuritySnapLockVollAttr {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP Security Snaplock volume attributes information from the Cluster Management Network
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
        Write-PscriboMessage "Collecting ONTAP Security Snaplock volume attributes information."
    }

    process {
        $Data =  Get-NcVserver | Where-Object {$_.VserverType -eq "data"}
        $VolumeFilter = Get-Ncvol | Where-Object {$_.VolumeSnaplockAttributes.SnaplockType -in "enterprise","compliance"}
        $OutObj = @()
        if ($Data -and $VolumeFilter) {
            foreach ($Item in $Data) {
                $VolumeFilter = Get-Ncvol -VserverContext $Item.Vserver | Where-Object {$_.VolumeSnaplockAttributes.SnaplockType -in "enterprise","compliance"}
                foreach ($vol in $VolumeFilter) {
                    $SnapLockVolAttr = Get-NcSnaplockVolAttr -Volume $vol.Name -VserverContext $Item.VserverName
                    $inObj = [ordered] @{
                        'Volume' = $vol.Name
                        'Aggregate' = $vol.Aggregate
                        'Snaplock Type' = $TextInfo.ToTitleCase($SnapLockVolAttr.Type)
                        'Maximum Retention Period' = $SnapLockVolAttr.MaximumRetentionPeriod
                        'Minimum Retention Period' = $SnapLockVolAttr.MinimumRetentionPeriod
                        'Privileged Delete State' = Switch ($SnapLockVolAttr.PrivilegedDeleteState) {
                            $Null { '-' }
                            default { $SnapLockVolAttr.PrivilegedDeleteState }
                        }
                        'Volume Expiry Time' = $SnapLockVolAttr.VolumeExpiryTime
                        'Volume Expiry Time Secs' = $SnapLockVolAttr.VolumeExpiryTimeSecs
                        'Auto Commit Period' = $SnapLockVolAttr.AutocommitPeriod
                        'Default Retention Period' = $SnapLockVolAttr.DefaultRetentionPeriod
                        'Litigation Count' = $SnapLockVolAttr.LitigationCount
                    }
                    $OutObj += [pscustomobject]$inobj
                }
            }

            $TableParams = @{
                Name = "Snaplock Volume Attributes Information - $($ClusterInfo.ClusterName)"
                List = $true
                ColumnWidths = 40, 60
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $OutObj | Table @TableParams
        }
    }

    end {}

}