function Get-AbrOntapStorageAGGR {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP storage summary information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.6.3
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
        Write-PscriboMessage "Collecting ONTAP storage aggregate information."
    }

    process {
        try {
            $AggrSpace = Get-NcAggr -Controller $Array
            if ($AggrSpace) {
                $AggrSpaceSummary = foreach ($Aggr in $AggrSpace) {
                    try {
                        $RootAggr = Get-NcAggr $Aggr.Name -Controller $Array | ForEach-Object{ $_.AggrRaidAttributes.HasLocalRoot }
                        [PSCustomObject] @{
                            'Name' = $Aggr.Name
                            'Capacity' = $Aggr.Totalsize | ConvertTo-FormattedNumber -Type Datasize -ErrorAction SilentlyContinue
                            'Available' = $Aggr.Available | ConvertTo-FormattedNumber -Type Datasize -ErrorAction SilentlyContinue
                            'Used' = $Aggr.Used | ConvertTo-FormattedNumber -Type Percent -ErrorAction SilentlyContinue
                            'Disk Count' = $Aggr.Disks
                            'Root' = ConvertTo-TextYN $RootAggr
                            'Raid Type' = ($Aggr.RaidType.Split(",")[0]).ToUpper()
                            'State' = $Aggr.State
                        }
                    }
                    catch {
                        Write-PscriboMessage -IsWarning $_.Exception.Message
                    }
                }
                if ($Healthcheck.Storage.Aggr) {
                    $AggrSpaceSummary | Where-Object { $_.'State' -eq 'failed' } | Set-Style -Style Critical -Property 'State'
                    $AggrSpaceSummary | Where-Object { $_.'State' -eq 'unknown' -or $_.'State' -eq 'offline' } | Set-Style -Style Warning -Property 'State'
                    $AggrSpaceSummary | Where-Object { $_.'Used' -ge 90 } | Set-Style -Style Critical -Property 'Used'
                }
                $TableParams = @{
                    Name = "Aggregates - $($ClusterInfo.ClusterName)"
                    List = $false
                    ColumnWidths = 27, 10, 10, 10, 10, 8, 15, 10
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $AggrSpaceSummary | Table @TableParams
            }
            try {
                if ($InfoLevel.Storage -ge 2) {
                    Section -Style Heading4 'Aggregate Options' {
                        $Aggregates = Get-NcAggr -Controller $Array | Where-Object {!$_.AggrRaidAttributes.HasLocalRoot}
                        foreach ($Aggregate in $Aggregates) {
                            try {
                                Section -Style Heading5 "$($Aggregate.Name) Options" {
                                    $OutObj = @()
                                    $Options = Get-NcAggrOption -Controller $Array -Name $Aggregate.Name
                                    $Option = @{}
                                    $Options | ForEach-Object {$Option.add($_.Name, $_.Value)}
                                    $inObj = [ordered] @{
                                        'azcs_read_optimization' = $TextInfo.ToTitleCase($Option.azcs_read_optimization)
                                        'dir_holes' = ConvertTo-TextYN $Option.dir_holes
                                        'dlog_hole_reserve' = $TextInfo.ToTitleCase($Option.dlog_hole_reserve)
                                        'enable_cold_data_reporting' = ConvertTo-TextYN $Option.enable_cold_data_reporting
                                        'encrypt_with_aggr_key' = ConvertTo-TextYN $Option.encrypt_with_aggr_key
                                        'free_space_realloc' = $TextInfo.ToTitleCase($Option.free_space_realloc)
                                        'fs_size_fixed' = $TextInfo.ToTitleCase($Option.fs_size_fixed)
                                        'ha_policy' = $TextInfo.ToTitleCase($Option.ha_policy)
                                        'hybrid_enabled' = ConvertTo-TextYN $Option.hybrid_enabled
                                        'ignore_inconsistent' = $TextInfo.ToTitleCase($Option.ignore_inconsistent)
                                        'logical_space_enforcement' = ConvertTo-TextYN $Option.logical_space_enforcement
                                        'logical_space_reporting' = ConvertTo-TextYN $Option.logical_space_reporting
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
                                    $OutObj += [pscustomobject]$inobj

                                    $TableParams = @{
                                        Name = "Aggregates Options - $($Aggregate.Name)"
                                        List = $true
                                        ColumnWidths = 50, 50
                                    }
                                    if ($Report.ShowTableCaptions) {
                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                    }
                                    $OutObj | Table @TableParams
                                }
                            }
                            catch {
                                Write-PscriboMessage -IsWarning $_.Exception.Message
                            }
                        }
                    }
                }
            }
            catch {
                Write-PscriboMessage -IsWarning $_.Exception.Message
            }
        }
        catch {
            Write-PscriboMessage -IsWarning $_.Exception.Message
        }
    }

    end {}

}