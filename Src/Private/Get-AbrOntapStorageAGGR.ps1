function Get-AbrOntapStorageAGGR {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP storage summary information from the Cluster Management Network
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
        Write-PScriboMessage 'Collecting ONTAP storage aggregate information.'
    }

    process {
        try {
            try {
                $ObjectData = Get-NcAggr -Controller $Array
                if ($ObjectData) {
                    $ObjectDataInfo = @()
                    foreach ($Data in $ObjectData) {
                        try {
                            $AggrOwner = (Get-NcAggr -Name $Data.Name ).AggrOwnershipAttributes
                            $inObj = [Ordered]@{
                                'Name' = $Data.Name
                                'Home Nodes' = ${AggrOwner}?.HomeName ?? '--'
                                'Owner Nodes' = ${AggrOwner}?.OwnerName ?? '--'
                                'Capacity' = ($Data.Totalsize | ConvertTo-FormattedNumber -ErrorAction SilentlyContinue -NumberFormatString 0.0 -Type Datasize) ?? '--'
                                'Available' = ($Data.Available | ConvertTo-FormattedNumber -ErrorAction SilentlyContinue -NumberFormatString 0.0 -Type Datasize) ?? '--'
                                'Used' = (($Data.Totalsize - $Data.Available ) | ConvertTo-FormattedNumber -ErrorAction SilentlyContinue -NumberFormatString 0.0 -Type Datasize) ?? '--'
                                'Disk Count' = $Data.Disks
                                'Root' = ((Get-NcAggr -Name $Data.Name -Controller $Array | ForEach-Object { $_.AggrRaidAttributes.HasLocalRoot }) -eq 'False') ? 'No': 'Yes'
                                'Raid Type' = (($Data.RaidType.Split(',')[0]).ToUpper()) ?? '--'
                                'Raid Size' = $Data.RaidSize
                                'Volumes in Aggregate' = $Data.Volumes
                                'State' = $Data.State
                            }
                            $ObjectDataInfo += [pscustomobject](ConvertTo-HashToYN $inObj)
                        } catch {
                            Write-PScriboMessage -IsWarning $_.Exception.Message
                        }
                    }

                    if ($Healthcheck.Storage.Aggr) {
                        $ObjectDataInfo | Where-Object { $_.'State' -eq 'failed' } | Set-Style -Style Critical -Property 'State'
                        $ObjectDataInfo | Where-Object { $_.'State' -eq 'unknown' -or $_.'State' -eq 'offline' } | Set-Style -Style Warning -Property 'State'
                        $ObjectDataInfo | Where-Object { $_.'Used' -ge 90 } | Set-Style -Style Critical -Property 'Used'
                    }

                    if ($InfoLevel.Storage -ge 2) {
                        Paragraph "The following sections detail the storage aggregate configuration and health status in $($ClusterInfo.ClusterName)."
                        foreach ($Data in $ObjectDataInfo) {
                            Section -Style NOTOCHeading4 -ExcludeFromTOC "$($Data.Name)" {
                                $TableParams = @{
                                    Name = "Aggregates - $($Data.Name)"
                                    List = $true
                                    ColumnWidths = 40, 60
                                }
                                if ($Report.ShowTableCaptions) {
                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                }
                                $Data | Table @TableParams
                                if ($Healthcheck.Storage.Aggr -and (($Data | Where-Object { $_.'State' -eq 'failed' } ) -or ($Data | Where-Object { $_.'State' -eq 'unknown' -or $_.'State' -eq 'offline' }) -or ($Data | Where-Object { $_.'Used' -ge 90 -and $_.'Root' -ne 'Yes' }))) {
                                    Paragraph 'Health Check:' -Bold -Underline
                                    BlankLine
                                    Paragraph {
                                        Text 'Best Practice:' -Bold
                                        Text 'Ensure that all Aggregates are in healthy state to maintain optimal storage performance and client access availability.'
                                    }
                                    BlankLine
                                }
                            }
                        }
                    } else {
                        Paragraph "The following table summarises the aggregates in $($ClusterInfo.ClusterName)."
                        BlankLine
                        $TableParams = @{
                            Name = "Aggregates - $($ClusterInfo.ClusterName)"
                            List = $false
                            Columns = 'Name', 'Capacity', 'Available', 'Used', 'Disk Count', 'Root', 'Raid Type', 'State'
                            ColumnWidths = 27, 10, 10, 10, 10, 8, 15, 10
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $ObjectDataInfo | Table @TableParams
                        if ($Healthcheck.Storage.Aggr -and (($ObjectDataInfo | Where-Object { $_.'State' -eq 'failed' } ) -or ($ObjectDataInfo | Where-Object { $_.'State' -eq 'unknown' -or $_.'State' -eq 'offline' }) -or ($ObjectDataInfo | Where-Object { $_.'Used' -ge 90 -and $_.'Root' -ne 'Yes' }))) {
                            Paragraph 'Health Check:' -Bold -Underline
                            BlankLine
                            Paragraph {
                                Text 'Best Practice:' -Bold
                                Text 'Ensure that all Aggregates are in healthy state to maintain optimal storage performance and client access availability.'
                            }
                            BlankLine
                        }
                    }
                }
            } catch {
                Write-PScriboMessage -IsWarning $($_.Exception.Message)
            }
            try {
                $AggrSpare = Get-NcAggrSpare -Controller $Array
                if ($AggrSpare) {
                    Section -Style Heading4 'Disk Spares' {
                        $OutObj = @()
                        foreach ($Spare in $AggrSpare) {
                            try {
                                $inObj = [ordered] @{
                                    'Name' = $Spare.Disk
                                    'Capacity' = ($Spare.TotalSize | ConvertTo-FormattedNumber -ErrorAction SilentlyContinue -NumberFormatString 0.0 -Type Datasize) ?? '--'
                                    'Root Usable' = ($Spare.LocalUsableRootSize | ConvertTo-FormattedNumber -ErrorAction SilentlyContinue -NumberFormatString 0.0 -Type Datasize) ?? '--'
                                    'Data Usable' = ($Spare.LocalUsableDataSize | ConvertTo-FormattedNumber -ErrorAction SilentlyContinue -NumberFormatString 0.0 -Type Datasize) ?? '--'
                                    'Shared Disk' = $Spare.IsDiskShared
                                    'Disk Zeroed' = $Spare.IsDiskZeroed
                                    'Owner' = $Spare.OriginalOwner
                                }
                                $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                            } catch {
                                Write-PScriboMessage -IsWarning $_.Exception.Message
                            }
                        }
                        if ($Healthcheck.Storage.Aggr) {
                            $OutObj | Where-Object { $_.'Disk Zeroed' -eq 'No' } | Set-Style -Style Warning -Property 'Disk Zeroed'
                        }
                        $TableParams = @{
                            Name = "Disk Spares - $($ClusterInfo.ClusterName)"
                            List = $false
                            ColumnWidths = 20, 12, 12, 12, 12, 12, 20
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
            try {
                if ($InfoLevel.Storage -ge 2) {
                    Section -Style Heading4 'Per Aggregate Options' {
                        $Aggregates = Get-NcAggr -Controller $Array | Where-Object { !$_.AggrRaidAttributes.HasLocalRoot }
                        foreach ($Aggregate in $Aggregates) {
                            try {
                                Section -ExcludeFromTOC -Style NOTOCHeading5 "$($Aggregate.Name)" {
                                    $OutObj = @()
                                    $Options = Get-NcAggrOption -Controller $Array -Name $Aggregate.Name
                                    $Option = @{}
                                    $Options | ForEach-Object { $Option.add($_.Name, $_.Value) }
                                    $inObj = [ordered] @{
                                        'azcs_read_optimization' = $TextInfo.ToTitleCase($Option.azcs_read_optimization)
                                        'dir_holes' = $Option.dir_holes
                                        'dlog_hole_reserve' = $TextInfo.ToTitleCase($Option.dlog_hole_reserve)
                                        'enable_cold_data_reporting' = $Option.enable_cold_data_reporting
                                        'encrypt_with_aggr_key' = $Option.encrypt_with_aggr_key
                                        'free_space_realloc' = $TextInfo.ToTitleCase($Option.free_space_realloc)
                                        'fs_size_fixed' = $TextInfo.ToTitleCase($Option.fs_size_fixed)
                                        'ha_policy' = $TextInfo.ToTitleCase($Option.ha_policy)
                                        'hybrid_enabled' = $Option.hybrid_enabled
                                        'ignore_inconsistent' = $TextInfo.ToTitleCase($Option.ignore_inconsistent)
                                        'logical_space_enforcement' = $Option.logical_space_enforcement
                                        'logical_space_reporting' = $Option.logical_space_reporting
                                        'max_write_alloc_blocks' = $TextInfo.ToTitleCase($Option.max_write_alloc_blocks)
                                        'nearly_full_threshold' = $TextInfo.ToTitleCase($Option.nearly_full_threshold)
                                        'no_delete_log' = $TextInfo.ToTitleCase($Option.no_delete_log)
                                        'no_i2p' = $TextInfo.ToTitleCase($Option.no_i2p)
                                        'nosnap' = $TextInfo.ToTitleCase($Option.nosnap)
                                        'percent_snapshot_space' = $TextInfo.ToTitleCase($Option.percent_snapshot_space)
                                        'raid_cv' = $TextInfo.ToTitleCase($Option.raid_cv)
                                        'raid_lost_write' = $TextInfo.ToTitleCase($Option.raid_lost_write)
                                        'raidsize' = $TextInfo.ToTitleCase($Option.raidsize)
                                        'raidtype' = $TextInfo.ToTitleCase($Option.raidtype)
                                        'resyncsnaptime' = $TextInfo.ToTitleCase($Option.resyncsnaptime)
                                        'single_instance_data_logging' = $TextInfo.ToTitleCase($Option.single_instance_data_logging)
                                        'snapmirrored' = $TextInfo.ToTitleCase($Option.snapmirrored)
                                        'snapshot_autodelete' = $TextInfo.ToTitleCase($Option.snapshot_autodelete)
                                        'striping' = $TextInfo.ToTitleCase($Option.striping)
                                        'thorough_scrub' = $TextInfo.ToTitleCase($Option.thorough_scrub)
                                    }
                                    $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)

                                    $TableParams = @{
                                        Name = "Options - $($Aggregate.Name)"
                                        List = $true
                                        ColumnWidths = 50, 50
                                    }
                                    if ($Report.ShowTableCaptions) {
                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                    }
                                    $OutObj | Table @TableParams
                                }
                            } catch {
                                Write-PScriboMessage -IsWarning $_.Exception.Message
                            }
                        }
                    }
                }
            } catch {
                Write-PScriboMessage -IsWarning $_.Exception.Message
            }
        } catch {
            Write-PScriboMessage -IsWarning $_.Exception.Message
        }
    }

    end {}

}