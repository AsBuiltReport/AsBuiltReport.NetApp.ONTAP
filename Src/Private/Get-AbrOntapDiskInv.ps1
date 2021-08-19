function Get-AbrOntapDiskInv {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP disk inventort information from the Cluster Management Network
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
        Write-PscriboMessage "Collecting ONTAP disk inventory per node."
    }

    process {
        $DiskInv = Get-NcDisk
        $NodeDiskBroken = Get-NcDisk | Where-Object{ $_.DiskRaidInfo.ContainerType -eq "broken" }
        if ($DiskInv) {
            $DiskInventory = foreach ($Disks in $DiskInv) {
                $DiskType = Get-NcDisk -Name $Disks.Name | ForEach-Object{ $_.DiskInventoryInfo }
                $DiskFailed = $NodeDiskBroken | Where-Object { $_.'Name' -eq $Disks.Name }
                if ($DiskFailed.Name -eq $Disks.Name ) {
                    $Disk = " $($DiskFailed.Name)(*)"
                    }
                    else {
                        $Disk =  $Disks.Name
                    }
                [PSCustomObject] @{
                    'Disk Name' = $Disk
                    'Shelf' = $Disks.Shelf
                    'Bay' = $Disks.Bay
                    'Capacity' = "$([math]::Round(($Disks.Capacity) / "1$($Unit)", 2))$Unit"
                    'Model' = $Disks.Model
                    'Type' = $DiskType.DiskType
                }
            }
            if ($Healthcheck.Storage.DiskStatus) {
                $DiskInventory | Where-Object { $_.'Disk Name' -like '*(*)' } | Set-Style -Style Critical -Property 'Disk Name'
            }
            $TableParams = @{
                Name = "Disk Inventory - $($ClusterInfo.ClusterName)"
                List = $false
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $DiskInventory | Table @TableParams
        }
        $DiskInv = Get-NcDisk
        $NodeDiskBroken = Get-NcDisk | Where-Object{ $_.DiskRaidInfo.ContainerType -eq "broken" }
        if ($DiskInv) {
            $DiskInventory = foreach ($Disks in $DiskInv) {
                $DiskType = Get-NcDisk -Name $Disks.Name | ForEach-Object{ $_.DiskInventoryInfo }
                $DiskFailed = $NodeDiskBroken | Where-Object { $_.'Name' -eq $Disks.Name }
                if ($DiskFailed.Name -eq $Disks.Name ) {
                    $Disk = " $($DiskFailed.Name)(*)"
                    }
                    else {
                        $Disk =  $Disks.Name
                    }
                [PSCustomObject] @{
                    'Disk Name' = $Disk
                    'Shelf' = $Disks.Shelf
                    'Bay' = $Disks.Bay
                    'SerialNumber' = $DiskType.SerialNumber
                    'Type' = $DiskType.DiskType
                }
            }
            if ($Healthcheck.Storage.DiskStatus) {
                $DiskInventory | Where-Object { $_.'Disk Name' -like '*(*)' } | Set-Style -Style Critical -Property 'Disk Name'
            }
            $TableParams = @{
                Name = "Disk Serial Number Inventory - $($ClusterInfo.ClusterName)"
                List = $false
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $DiskInventory | Table @TableParams
        }
    }

    end {}

}