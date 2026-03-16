function Get-AbrOntapDiskInv {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP disk inventort information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.6.12
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
        Write-PScriboMessage 'Collecting ONTAP disk inventory per node.'
    }

    process {
        try {
            $DiskInv = Get-NcDisk -Controller $Array
            $NodeDiskBroken = Get-NcDisk -Controller $Array | Where-Object { $_.DiskRaidInfo.ContainerType -eq 'broken' }
            if ($DiskInv) {
                $OutObj = @()
                foreach ($Disks in $DiskInv) {
                    try {
                        $DiskType = Get-NcDisk -Controller $Array -Name $Disks.Name | ForEach-Object { $_.DiskInventoryInfo }
                        $inObj = [ordered] @{
                            'Disk Name' = $Disks.Name
                            'Shelf' = $Disks.Shelf
                            'Bay' = $Disks.Bay
                            'Capacity' = ($Disks.Capacity | ConvertTo-FormattedNumber -ErrorAction SilentlyContinue -NumberFormatString 0.0 -Type Disksize) ?? '--'
                            'Model' = $Disks.Model
                            'Serial Number' = $DiskType.SerialNumber
                            'Firmware' = $Disks.FW
                            'Type' = $DiskType.DiskType
                            'Aggregate' = $Disks.Aggregate
                        }
                        $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }

                if ($Healthcheck.Storage.DiskStatus) {
                    $OutObj | Where-Object { $_.'Disk Name' -like '*(*)' } | Set-Style -Style Critical -Property 'Disk Name'
                }

                if ($InfoLevel.Storage -ge 2) {
                    foreach ($Disks in $Outobj) {
                        Section -Style NOTOCHeading4 -ExcludeFromTOC "$($Disks.'Disk Name')" {
                            $TableParams = @{
                                Name = "Disk Inventory - $($Disks.'Disk Name')"
                                List = $true
                                ColumnWidths = 40, 60
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $Disks | Select-Object -ExcludeProperty 'Disk Name' | Table @TableParams
                            if ($Healthcheck.Cluster.AutoSupport -and ($Disks | Where-Object { $_.'Enabled' -like 'No' })) {
                                Paragraph 'Health Check:' -Bold -Underline
                                BlankLine
                                Paragraph {
                                    Text 'Best Practice:' -Bold
                                    Text 'AutoSupport is disabled on one or more nodes. It is recommended to enable AutoSupport to ensure proactive monitoring and issue resolution.'
                                }
                                BlankLine
                            }
                        }
                    }
                } else {
                    $TableParams = @{
                        Name = "Disk Inventory - $($ClusterInfo.ClusterName)"
                        List = $false
                        Columns = 'Disk Name', 'Shelf', 'Bay', 'Capacity', 'Model', 'Type', 'Firmware'
                        ColumnWidths = 18, 13, 10, 10, 25, 12, 12
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $OutObj | Table @TableParams
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning $_.Exception.Message
        }
    }

    end {}

}