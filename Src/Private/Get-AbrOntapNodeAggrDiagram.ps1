function Get-AbrOntapStorageAggrDiagram {
    <#
    .SYNOPSIS
        Used by As Built Report to built NetApp ONTAP storage aggregate diagram
    .DESCRIPTION

    .NOTES
        Version:        0.6.8
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
        Write-PScriboMessage "Generating Storage Aggregates Diagram for NetApp ONTAP."
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

            SubGraph Cluster -Attributes @{Label = $ClusterInfo.ClusterName; fontsize = 22; penwidth = 1.5; labelloc = 't'; style = "dashed,rounded"; color = "gray" } {
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

                    foreach ($Node in $NodeSum) {
                        $ClusterHa = Get-NcClusterHa -Node $Node.Node -Controller $Array

                        $NodeMgmtAddress = Get-NcNetInterface -Controller $Array | Where-Object { $_.Role -eq 'node_mgmt' -and $_.HomeNode -eq $Node.Node } | Select-Object -ExpandProperty Address
                        $NodeInterClusterAddress = Get-NcNetInterface -Controller $Array | Where-Object { $_.Role -eq 'intercluster' -and $_.HomeNode -eq $Node.Node } | Select-Object -ExpandProperty Address

                        if ($ClusterHa.Name -notin $HAObject.Partner) {
                            $HAObject += [PSCustomObject][ordered]@{
                                "Name" = $ClusterHa.Name
                                "Partner" = $ClusterHa.Partner
                                "HAState" = $ClusterHa.State
                            }
                        }

                        $NodeAdditionalInfo += [PSCustomObject][ordered]@{
                            'NodeName' = $Node.Node
                            'AdditionalInfo' = [PSCustomObject][ordered]@{
                                "System Id" = $Node.NodeSystemId
                                "Serial" = $Node.NodeSerialNumber
                                "Model" = $Node.NodeSerialNumber
                                "Mgmt" = switch ([string]::IsNullOrEmpty($NodeMgmtAddress)) {
                                    $true { "Unknown" }
                                    $false { $NodeMgmtAddress }
                                    Default { "Unknown" }
                                }
                            }
                        }

                        $NodeAggr = Get-NcAggr | Where-Object { $_.Nodes -eq $Node.Node }
                        foreach ($Aggr in $NodeAggr) {
                            $AggrInfo += [PSCustomObject][ordered]@{
                                "NodeName" = $Node.Node
                                "AggregateName" = $Aggr.Name
                                "AdditionalInfo" = [PSCustomObject][ordered]@{
                                    "Total Size" = $Aggr.TotalSize | ConvertTo-FormattedNumber -Type Datasize -ErrorAction SilentlyContinue
                                    "Used Space" = $Aggr.Used | ConvertTo-FormattedNumber -Type Datasize -ErrorAction SilentlyContinue
                                    "Assigned Disk" = $Aggr.Disks
                                    "Raid Type" = switch ([string]::IsNullOrEmpty($Aggr.RaidType)) {
                                        $true { "Unknown" }
                                        $false {
                                            & {
                                                switch ($Aggr.RaidType.Split(", ")[0]) {
                                                    "raid4" { "RAID 4" }
                                                    "raid_dp" { "RAID DP" }
                                                    "raid0" { "RAID 0" }
                                                    "raid1" { "RAID 1" }
                                                    "raid10" { "RAID 10" }
                                                    Default { "Unknown" }
                                                }
                                            }
                                        }
                                        Default { "Unknown" }
                                    }
                                    "Raid Size" = $Aggr.RaidSize
                                    "State" = $Aggr.State
                                }
                            }
                        }
                    }

                    $ClusterNodesObj = @()

                    foreach ($Node in $NodeAdditionalInfo) {
                        $ClusterNodeObj = @()
                        $ClusterNodeObj += Add-DiaHTMLNodeTable -ImagesObj $Images -inputObject $Node.NodeName -Align "Center" -iconType "Ontap_Node" -columnSize 1 -IconDebug $IconDebug -MultiIcon -AditionalInfo $Node.AdditionalInfo -Subgraph -SubgraphLabel $Node.NodeName -SubgraphLabelPos "top" -SubgraphTableStyle "dashed,rounded" -TableBorderColor "#71797E" -TableBorder 0 -SubgraphLabelFontsize 22 -fontSize 18

                        if ($ClusterNodeObj) {
                            if ($AggrInfo.Count -eq 1) {
                                $AggrInfoColumnSize = 1
                            } elseif ($ColumnSize) {
                                $AggrInfoColumnSize = $ColumnSize
                            } else {
                                $AggrInfoColumnSize = $AggrInfo.Count
                            }
                            $ClusterNodeObj += Add-DiaHTMLNodeTable -ImagesObj $Images -inputObject ($AggrInfo | Where-Object { $_.NodeName -eq $Node.Nodename }).AggregateName -Align "Center" -iconType "Ontap_Aggregate" -columnSize $AggrInfoColumnSize -IconDebug $IconDebug -MultiIcon -AditionalInfo ($AggrInfo | Where-Object { $_.NodeName -eq $Node.Nodename }).AdditionalInfo -Subgraph -SubgraphLabel "Aggregates" -SubgraphLabelPos "top" -SubgraphTableStyle "dashed,rounded" -TableBorderColor "#71797E" -TableBorder 1 -SubgraphLabelFontsize 22 -fontSize 18
                        }

                        if ($ClusterNodeObj) {
                            $ClusterNodeSubgraphObj = Add-DiaHTMLSubGraph -ImagesObj $Images -TableArray $ClusterNodeObj -Align 'Center' -IconDebug $IconDebug -Label " " -LabelPos 'top' -TableStyle "dashed,rounded" -TableBorderColor $Edgecolor -TableBorder 1 -columnSize 1 -fontSize 12
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
                        $ClusterMgmtObj = Add-DiaHTMLSubGraph -ImagesObj $Images -TableArray $ClusterNodesObj -Align 'Right' -IconDebug $IconDebug -Label "Management: $($ClusterInfo.NcController)" -LabelPos 'down' -TableStyle "dashed,rounded" -TableBorderColor $Edgecolor -TableBorder 0 -columnSize $ClusterNodesObjColumnSize -fontSize 18

                        if ($ClusterMgmtObj) {
                            Node Cluster @{Label = $ClusterMgmtObj; shape = 'plain'; fillColor = 'transparent'; fontsize = 14 }

                        } else {
                            Write-PScriboMessage -IsWarning "Unable to create ClusterNodesObj. No Cluster Management Object found."
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