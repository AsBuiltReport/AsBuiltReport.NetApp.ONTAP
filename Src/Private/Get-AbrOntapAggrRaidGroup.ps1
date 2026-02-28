function Get-AbrOntapAggrRaidGroup {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP aggregate RAID group information from the Cluster Management Network
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
        Write-PScriboMessage 'Collecting ONTAP aggregate RAID group information.'
    }

    process {
        try {
            $Disks = Get-NcDisk -Controller $Array | Where-Object { $_.DiskRaidInfo.ContainerType -eq 'aggregate' }
            if ($Disks) {
                $RaidGroups = $Disks | Group-Object { $_.DiskRaidInfo.RaidGroup }
                $OutObj = @()
                foreach ($RaidGroup in $RaidGroups) {
                    try {
                        # Parse RAID group path: /aggr_name/plex_name/rg_name
                        $RaidGroupParts = $RaidGroup.Name -split '/'
                        $AggrName = if ($RaidGroupParts.Count -ge 2) { $RaidGroupParts[1] } else { '--' }
                        $PlexName = if ($RaidGroupParts.Count -ge 3) { $RaidGroupParts[2] } else { '--' }
                        $RgName = if ($RaidGroupParts.Count -ge 4) { $RaidGroupParts[3] } else { '--' }
                        $DataCount = ($RaidGroup.Group | Where-Object { $_.DiskRaidInfo.RaidGroupPosition -eq 'data' }).Count
                        $ParityCount = ($RaidGroup.Group | Where-Object { $_.DiskRaidInfo.RaidGroupPosition -eq 'parity' }).Count
                        $DParityCount = ($RaidGroup.Group | Where-Object { $_.DiskRaidInfo.RaidGroupPosition -eq 'dparity' }).Count

                        $inObj = [ordered] @{
                            'Aggregate' = $AggrName
                            'Plex' = $PlexName
                            'RAID Group' = $RgName
                            'Total Disks' = $RaidGroup.Count
                            'Data Disks' = $DataCount
                            'Parity Disks' = $ParityCount
                            'DParity Disks' = $DParityCount
                        }
                        $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }
                if ($InfoLevel.Storage -ge 2) {
                    foreach ($AggrName in ($OutObj.'Aggregate' | Select-Object -Unique)) {
                        Section -ExcludeFromTOC -Style NOTOCHeading5 $AggrName {
                            $AggrRgs = $OutObj | Where-Object { $_.Aggregate -eq $AggrName }
                            $TableParams = @{
                                Name = "RAID Groups - $AggrName"
                                List = $false
                                Columns = 'Plex', 'RAID Group', 'Total Disks', 'Data Disks', 'Parity Disks', 'DParity Disks'
                                ColumnWidths = 18, 18, 16, 16, 16, 16
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $AggrRgs | Table @TableParams
                        }
                    }
                } else {
                    $TableParams = @{
                        Name = "Aggregate RAID Groups - $($ClusterInfo.ClusterName)"
                        List = $false
                        ColumnWidths = 20, 15, 15, 13, 13, 12, 12
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
