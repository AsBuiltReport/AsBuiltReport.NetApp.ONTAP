function Get-AbrOntapDiskInv {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP disk inventort information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.6.7
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
        Write-PScriboMessage "Collecting ONTAP disk inventory per node."
    }

    process {
        try {
            $DiskInv = Get-NcDisk -Controller $Array
            $NodeDiskBroken = Get-NcDisk -Controller $Array | Where-Object { $_.DiskRaidInfo.ContainerType -eq "broken" }
            if ($DiskInv) {
                $DiskInventory = foreach ($Disks in $DiskInv) {
                    try {
                        $DiskType = Get-NcDisk -Controller $Array -Name $Disks.Name | ForEach-Object { $_.DiskInventoryInfo }
                        $DiskFailed = $NodeDiskBroken | Where-Object { $_.'Name' -eq $Disks.Name }
                        if ($DiskFailed.Name -eq $Disks.Name ) {
                            $Disk = " $($DiskFailed.Name)(*)"
                        } else {
                            $Disk = $Disks.Name
                        }
                        [PSCustomObject] @{
                            'Disk Name' = $Disk
                            'Shelf' = $Disks.Shelf
                            'Bay' = $Disks.Bay
                            'Capacity' = $Disks.Capacity | ConvertTo-FormattedNumber -Type Disksize -ErrorAction SilentlyContinue
                            'Model' = $Disks.Model
                            'Serial Number' = $DiskType.SerialNumber
                            'Type' = $DiskType.DiskType
                        }
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }
                if ($Healthcheck.Storage.DiskStatus) {
                    $DiskInventory | Where-Object { $_.'Disk Name' -like '*(*)' } | Set-Style -Style Critical -Property 'Disk Name'
                }
                $TableParams = @{
                    Name = "Disk Inventory - $($ClusterInfo.ClusterName)"
                    List = $false
                    ColumnWidths = 15, 10, 10, 10, 25, 18, 12
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $DiskInventory | Table @TableParams
            }
        } catch {
            Write-PScriboMessage -IsWarning $_.Exception.Message
        }
    }

    end {}

}