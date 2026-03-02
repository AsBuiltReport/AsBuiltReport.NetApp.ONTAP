function Get-AbrOntapStorageAggrDiagram {
    <#
    .SYNOPSIS
        Used by As Built Report to built NetApp ONTAP storage aggregate diagram
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
        Write-PScriboMessage 'Generating Storage Aggregates Diagram for NetApp ONTAP.'
        # Used for DiagramDebug
        if ($Options.EnableDiagramDebug) {
            $EdgeDebug = @{style = 'filled'; color = 'red' }
            $SubGraphDebug = @{style = 'dashed'; color = 'red' }
            $NodeDebug = @{color = 'black'; style = 'red'; shape = 'plain' }
            $NodeDebugEdge = @{color = 'black'; style = 'red'; shape = 'plain' }
            $IconDebug = $true
        } else {
            $EdgeDebug = @{style = 'invis'; color = 'red' }
            $SubGraphDebug = @{style = 'invis'; color = 'gray' }
            $NodeDebug = @{color = 'transparent'; style = 'transparent'; shape = 'point' }
            $NodeDebugEdge = @{color = 'transparent'; style = 'transparent'; shape = 'none' }
            $IconDebug = $false
        }

        if ($Options.DiagramTheme -eq 'Black') {
            $Edgecolor = 'White'
            $Fontcolor = 'White'
        } elseif ($Options.DiagramTheme -eq 'Neon') {
            $Edgecolor = 'gold2'
            $Fontcolor = 'gold2'
        } else {
            $Edgecolor = '#71797E'
            $Fontcolor = '#565656'
        }
    }

    process {
        try {
            $ClusterInfo = Get-NcCluster -Controller $Array
            $NodeSum = Get-NcNode -Controller $Array

            SubGraph Cluster -Attributes @{Label = $ClusterInfo.ClusterName; fontsize = 22; penwidth = 1.5; labelloc = 't'; style = 'dashed,rounded'; color = 'gray' } {
                try {

                    if ($NodeSum.Count -eq 1) {
                        $NodeSumColumnSize = 1
                    } elseif ($ColumnSize) {
                        $NodeSumColumnSize = $ColumnSize
                    } else {
                        $NodeSumColumnSize = $NodeSum.Count
                    }

                    $HAObject = @()

                    $NodeAdditionalInfo = @()
                    $AggrInfo = @()

                    # Collect RAID group data per aggregate
                    # Primary: use REST API
                    $AggrRaidGroupData = [ordered]@{}
                    try {
                        $AggrRestData = Get-NetAppOntapAPI -uri '/api/storage/aggregates?fields=name,block_storage.plexes&return_records=true&return_timeout=15'
                        if ($AggrRestData) {
                            foreach ($AggrRest in $AggrRestData) {
                                $RgNames = @()
                                if ($AggrRest.block_storage.plexes) {
                                    foreach ($Plex in $AggrRest.block_storage.plexes) {
                                        if ($Plex.raid_groups) {
                                            foreach ($RG in $Plex.raid_groups) {
                                                $RgNames += "$($Plex.name)/$($RG.name)"
                                            }
                                        }
                                    }
                                }
                                $AggrRaidGroupData[$AggrRest.name] = $RgNames
                            }
                        }
                    } catch {
                        Write-PScriboMessage -IsWarning "Unable to retrieve aggregate RAID group info from REST API: $($_.Exception.Message)"
                    }

                    # Fallback: SSH if REST API returned no RAID group data
                    if (($AggrRaidGroupData.Values | Where-Object { $_.Count -gt 0 }).Count -eq 0) {
                        try {
                            # Run diagnostics command to list disk partition RAID group assignments.
                            # Output line format: <Partition> <Size> aggregate <ContainerPath> <Owner>
                            # ContainerPath format: /AggregateName/PlexName/RaidGroupName
                            $SshResult = Invoke-NcSsh -Command 'set diag -confirmations off;storage disk partition show' -Controller $Array
                            if ($SshResult.Value) {
                                foreach ($Line in ($SshResult.Value -split "`n")) {
                                    # Match lines: <Partition> <Size> aggregate /<Aggregate>/<Plex>/<RaidGroup> <Owner>
                                    if ($Line -match '^\s+\S+\s+\S+\s+aggregate\s+(\/\S+)\s+\S+') {
                                        # ContainerPath parts: [0]=AggregateName, [1]=PlexName, [2]=RaidGroupName
                                        $Parts = $Matches[1].TrimStart('/').Split('/')
                                        if ($Parts.Count -ge 3) {
                                            $AggrN = $Parts[0]
                                            $PlexN = $Parts[1]
                                            $RgN = $Parts[2]
                                            $RgKey = "$PlexN/$RgN"
                                            if (-not $AggrRaidGroupData.ContainsKey($AggrN)) {
                                                $AggrRaidGroupData[$AggrN] = @()
                                            }
                                            if ($RgKey -notin $AggrRaidGroupData[$AggrN]) {
                                                $AggrRaidGroupData[$AggrN] += $RgKey
                                            }
                                        }
                                    }
                                }
                            }
                        } catch {
                            Write-PScriboMessage -IsWarning "Unable to retrieve partition info via SSH: $($_.Exception.Message)"
                        }
                    }

                    foreach ($Node in $NodeSum) {
                        $ClusterHa = Get-NcClusterHa -Node $Node.Node -Controller $Array

                        $NodeMgmtAddress = Get-NcNetInterface -Controller $Array | Where-Object { $_.Role -eq 'node_mgmt' -and $_.HomeNode -eq $Node.Node } | Select-Object -ExpandProperty Address
                        $NodeInterClusterAddress = Get-NcNetInterface -Controller $Array | Where-Object { $_.Role -eq 'intercluster' -and $_.HomeNode -eq $Node.Node } | Select-Object -ExpandProperty Address

                        if ($ClusterHa.Name -notin $HAObject.Partner) {
                            $HAObject += [PSCustomObject][ordered]@{
                                'Name' = $ClusterHa.Name
                                'Partner' = $ClusterHa.Partner
                                'HAState' = $ClusterHa.State
                            }
                        }

                        $NodeAdditionalInfo += [PSCustomObject][ordered]@{
                            'NodeName' = $Node.Node
                            'AdditionalInfo' = [PSCustomObject][ordered]@{
                                'System Id' = $Node.NodeSystemId
                                'Serial' = $Node.NodeSerialNumber
                                'Model' = $Node.NodeModel
                                'Mgmt' = switch ([string]::IsNullOrEmpty($NodeMgmtAddress)) {
                                    $true { 'Unknown' }
                                    $false { $NodeMgmtAddress }
                                    default { 'Unknown' }
                                }
                            }
                        }

                        $NodeAggr = Get-NcAggr | Where-Object { $_.Nodes -eq $Node.Node }
                        foreach ($Aggr in $NodeAggr) {
                            $RgInfo = if ($AggrRaidGroupData.ContainsKey($Aggr.Name) -and $AggrRaidGroupData[$Aggr.Name]) {
                                ($AggrRaidGroupData[$Aggr.Name] | Sort-Object) -join ', '
                            } else {
                                'N/A'
                            }
                            $AggrInfo += [PSCustomObject][ordered]@{
                                'NodeName' = $Node.Node
                                'AggregateName' = $Aggr.Name
                                'AdditionalInfo' = [PSCustomObject][ordered]@{
                                    'Total Size' = $Aggr.TotalSize | ConvertTo-FormattedNumber -NumberFormatString 0.0 -Type Datasize -ErrorAction SilentlyContinue
                                    'Used Space' = ($Aggr.TotalSize - $Aggr.Available) | ConvertTo-FormattedNumber -NumberFormatString 0.0 -Type Datasize -ErrorAction SilentlyContinue
                                    'Assigned Disk' = $Aggr.Disks
                                    'Raid Type' = switch ([string]::IsNullOrEmpty($Aggr.RaidType)) {
                                        $true { 'Unknown' }
                                        $false {
                                            & {
                                                switch ($Aggr.RaidType.Split(', ')[0]) {
                                                    'raid4' { 'RAID 4' }
                                                    'raid_dp' { 'RAID DP' }
                                                    'raid0' { 'RAID 0' }
                                                    'raid1' { 'RAID 1' }
                                                    'raid10' { 'RAID 10' }
                                                    default { 'Unknown' }
                                                }
                                            }
                                        }
                                        default { 'Unknown' }
                                    }
                                    'Raid Size' = $Aggr.RaidSize
                                    'RAID Groups' = $RgInfo
                                    'State' = switch ([string]::IsNullOrEmpty($Aggr.State)) {
                                        $true { 'Unknown' }
                                        $false { $Aggr.State.ToUpper() }
                                        default { 'Unknown' }
                                    }
                                }
                            }
                        }
                    }

                    $ClusterNodesObj = @()

                    foreach ($Node in $NodeAdditionalInfo) {
                        $ClusterNodeObj = @()
                        $ClusterNodeObj += Add-DiaHtmlNodeTable -Name 'ClusterNodeObj' -ImagesObj $Images -inputObject $Node.NodeName -Align 'Center' -iconType 'Ontap_Node' -ColumnSize 1 -IconDebug $IconDebug -MultiIcon -AditionalInfo $Node.AdditionalInfo -Subgraph -SubgraphLabel $Node.NodeName -SubgraphLabelPos 'top' -SubgraphTableStyle 'dashed,rounded' -TableBorderColor '#71797E' -TableBorder 0 -SubgraphLabelFontSize 22 -FontSize 18

                        if ($ClusterNodeObj) {
                            if ($AggrInfo.Count -eq 1) {
                                $AggrInfoColumnSize = 1
                            } elseif ($ColumnSize) {
                                $AggrInfoColumnSize = $ColumnSize
                            } else {
                                $AggrInfoColumnSize = $AggrInfo.Count
                            }
                            $ClusterNodeObj += Add-DiaHtmlNodeTable -Name 'ClusterNodeObj' -ImagesObj $Images -inputObject ($AggrInfo | Where-Object { $_.NodeName -eq $Node.Nodename }).AggregateName -Align 'Center' -iconType 'Ontap_Aggregate' -ColumnSize $AggrInfoColumnSize -IconDebug $IconDebug -MultiIcon -AditionalInfo ($AggrInfo | Where-Object { $_.NodeName -eq $Node.Nodename }).AdditionalInfo -Subgraph -SubgraphLabel 'Aggregates' -SubgraphLabelPos 'top' -SubgraphTableStyle 'dashed,rounded' -TableBorderColor '#71797E' -TableBorder 1 -SubgraphLabelFontSize 22 -FontSize 18
                        }

                        if ($ClusterNodeObj) {
                            $ClusterNodeSubgraphObj = Add-DiaHtmlSubGraph -Name 'ClusterNodeSubgraphObj' -ImagesObj $Images -TableArray $ClusterNodeObj -Align 'Center' -IconDebug $IconDebug -Label ' ' -LabelPos 'top' -TableStyle 'dashed,rounded' -TableBorderColor $Edgecolor -TableBorder 1 -ColumnSize 1 -FontSize 12
                        }

                        $ClusterNodesObj += $ClusterNodeSubgraphObj
                    }

                    if ($ClusterNodesObj) {
                        if ($ClusterNodesObj.Count -eq 1) {
                            $ClusterNodesObjColumnSize = 1
                        } elseif ($ColumnSize) {
                            $ClusterNodesObjColumnSize = $ColumnSize
                        } else {
                            $ClusterNodesObjColumnSize = $ClusterNodesObj.Count
                        }
                        $ClusterMgmtObj = Add-DiaHtmlSubGraph -Name 'ClusterMgmtObj' -ImagesObj $Images -TableArray $ClusterNodesObj -Align 'Right' -IconDebug $IconDebug -Label "Management: $($ClusterInfo.NcController.Name)" -LabelPos 'down' -TableStyle 'dashed,rounded' -TableBorderColor $Edgecolor -TableBorder 0 -ColumnSize $ClusterNodesObjColumnSize -FontSize 18

                        if ($ClusterMgmtObj) {
                            Node ClusterAggrs @{Label = $ClusterMgmtObj; shape = 'plain'; fillColor = 'transparent'; fontsize = 14 }

                        } else {
                            Write-PScriboMessage -IsWarning 'Unable to create ClusterNodesObj. No Cluster Management Object found.'
                        }
                    }
                } catch {
                    Write-PScriboMessage -IsWarning $_.Exception.Message
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning $_.Exception.Message
        }
    }

    end {}

}