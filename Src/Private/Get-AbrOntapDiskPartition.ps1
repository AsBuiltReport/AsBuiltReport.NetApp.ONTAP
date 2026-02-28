function Get-AbrOntapDiskPartition {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP disk partition information from the Cluster Management Network
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
        Write-PScriboMessage 'Collecting ONTAP disk partition information.'
    }

    process {
        try {
            $DiskPartitions = Get-NcDisk -Controller $Array | Where-Object { $_.Name -match 'P\d+$' }
            if ($DiskPartitions) {
                $OutObj = @()
                foreach ($Partition in $DiskPartitions) {
                    try {
                        $PhysicalDiskName = $Partition.Name -replace 'P\d+$', ''
                        $RaidGroupParts = $Partition.DiskRaidInfo.RaidGroup -split '/'
                        $PlexName = if ($RaidGroupParts.Count -ge 3) { $RaidGroupParts[2] } else { '--' }
                        $RgName = if ($RaidGroupParts.Count -ge 4) { $RaidGroupParts[3] } else { '--' }

                        $inObj = [ordered] @{
                            'Partition' = $Partition.Name
                            'Physical Disk' = $PhysicalDiskName
                            'Container Type' = $Partition.DiskRaidInfo.ContainerType ?? '--'
                            'Aggregate' = $Partition.Aggregate ?? '--'
                            'Plex' = $PlexName
                            'RAID Group' = $RgName
                            'Position' = $Partition.DiskRaidInfo.RaidGroupPosition ?? '--'
                            'Owner' = $Partition.DiskOwnershipInfo.HomeNodeName ?? '--'
                        }
                        $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }
                if ($InfoLevel.Storage -ge 2) {
                    foreach ($Partition in $OutObj) {
                        Section -ExcludeFromTOC -Style NOTOCHeading5 $Partition.Partition {
                            $TableParams = @{
                                Name = "Disk Partition - $($Partition.Partition)"
                                List = $true
                                ColumnWidths = 40, 60
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $Partition | Table @TableParams
                        }
                    }
                } else {
                    $TableParams = @{
                        Name = "Disk Partitions - $($ClusterInfo.ClusterName)"
                        List = $false
                        Columns = 'Partition', 'Physical Disk', 'Container Type', 'Aggregate', 'RAID Group', 'Position', 'Owner'
                        ColumnWidths = 15, 15, 14, 14, 12, 12, 18
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
