function Get-AbrOntapVserverVolumes {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP vserver volumes information from the Cluster Management Network
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
        Write-PscriboMessage "Collecting ONTAP Vserver volumes information."
    }

    process {
        $Unit = "GB"
        $VserverRootVol = Get-NcVol | Where-Object {$_.JunctionPath -ne '/' -and $_.Name -ne 'vol0'}
        $VserverObj = @()
        if ($VserverRootVol) {
            foreach ($Item in $VserverRootVol) {
                $inObj = [ordered] @{
                    'Volume' = $Item.Name
                    'Vserver' = $Item.Vserver
                    'Status' = $Item.State
                    'Capacity' = "$([math]::Round(($Item.Totalsize) / "1$($Unit)", 0))$Unit"
                    'Available' = "$([math]::Round(($Item.Available) / "1$($Unit)", 0))$Unit"
                    'Used' = "$($Item.Used)%"
                    'Aggregate' = $Item.Aggregate
                }
                $VserverObj += [pscustomobject]$inobj
            }
            if ($Healthcheck.Vserver.Status) {
                $VserverObj | Where-Object { $_.'Status' -like 'offline' } | Set-Style -Style Warning -Property 'Status'
            }

            $TableParams = @{
                Name = "Vserver Volume Information - $($ClusterInfo.ClusterName)"
                List = $false
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $VserverObj | Table @TableParams
        }
        $VserverClonedVol = Get-NcVolClone
        $VserverObj = @()
        if ($VserverClonedVol) {
            foreach ($Item in $VserverClonedVol) {
                $inObj = [ordered] @{
                    'Volume' = $Item.Name
                    'Vserver' = $Item.Vserver
                    'ParentVolume' = $Item.ParentVolume
                    'Volume Type' = $Item.VolumeType.ToUpper()
                    'Parent Snapshot' = $Item.ParentSnapshot
                    'Space Reserve' = $Item.SpaceReserve
                    'Space Guarantee' = $Item.SpaceGuaranteeEnabled
                    'Capacity' = "$([math]::Round(($Item.Size - $Item.Used) / "1$($Unit)", 0))$Unit"
                    'Available' = "$([math]::Round(($Item.Available) / "1$($Unit)", 0))$Unit"
                    'Used' = "$($Item.Used)%"
                    'Aggregate' = $Item.Aggregate
                }
                $VserverObj += [pscustomobject]$inobj
            }
            if ($Healthcheck.Vserver.Status) {
                $VserverObj | Where-Object { $_.'Status' -like 'offline' } | Set-Style -Style Warning -Property 'Status'
            }

            $TableParams = @{
                Name = "Vserver Cloned Volumes Information - $($ClusterInfo.ClusterName)"
                List = $true
                ColumnWidths = 25, 75
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $VserverObj | Table @TableParams
        }
        $VserverClonedVol = Get-NcVolClone
        $VserverObj = @()
        if ($VserverClonedVol) {
            foreach ($Item in $VserverClonedVol) {
                $inObj = [ordered] @{
                    'Volume' = $Item.Name
                    'Vserver' = $Item.Vserver
                    'ParentVolume' = $Item.ParentVolume
                    'Volume Type' = $Item.VolumeType.ToUpper()
                    'Parent Snapshot' = $Item.ParentSnapshot
                    'Space Reserve' = $Item.SpaceReserve
                    'Space Guarantee' = $Item.SpaceGuaranteeEnabled
                    'Capacity' = "$([math]::Round(($Item.Size - $Item.Used) / "1$($Unit)", 0))$Unit"
                    'Available' = "$([math]::Round(($Item.Available) / "1$($Unit)", 0))$Unit"
                    'Used' = "$($Item.Used)%"
                    'Aggregate' = $Item.Aggregate
                }
                $VserverObj += [pscustomobject]$inobj
            }
            if ($Healthcheck.Vserver.Status) {
                $VserverObj | Where-Object { $_.'Status' -like 'offline' } | Set-Style -Style Warning -Property 'Status'
            }

            $TableParams = @{
                Name = "Vserver Cloned Volumes Information - $($ClusterInfo.ClusterName)"
                List = $true
                ColumnWidths = 25, 75
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $VserverObj | Table @TableParams
        }
    }

    end {}

}