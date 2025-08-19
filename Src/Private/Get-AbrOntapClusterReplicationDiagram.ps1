function Get-AbrOntapClusterReplicationDiagram {
    <#
    .SYNOPSIS
        Used by As Built Report to built NetApp ONTAP cluster diagram
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
        Write-PScriboMessage "Generating Cluster Replication Diagram for NetApp ONTAP."
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

            if ($NodeSum.Count -eq 1) {
                $NodeSumColumnSize = 1
            } elseif ($ColumnSize) {
                $NodeSumColumnSize = $ColumnSize
            } else {
                $NodeSumColumnSize = $NodeSum.Count
            }

            $HAObject = @()

            $NodeAdditionalInfo = @()

            foreach ($Node in $NodeSum) {
                $ClusterHa = Get-NcClusterHa -Node $Node.Node -Controller $Array

                $NodeMgmtAddress = Get-NcNetInterface -Controller $Array | Where-Object { $_.Role -eq 'node_mgmt' -and $_.HomeNode -eq $Node.Node } | Select-Object -ExpandProperty Address
                $NodeInterClusterAddress = Get-NcNetInterface -Controller $Array | Where-Object { $_.Role -eq 'intercluster' -and $_.HomeNode -eq $Node.Node } | Select-Object -ExpandProperty Address

                if ($ClusterHa.Name -notin $HAObject.Partner) {
                    $HAObject += [PSCustomObject][ordered]@{
                        "HAState" = $ClusterHa.State
                    }
                }

                $NodeAdditionalInfo += [PSCustomObject][ordered]@{
                    "Management" = switch ([string]::IsNullOrEmpty($NodeMgmtAddress)) {
                        $true { "Unknown" }
                        $false { $NodeMgmtAddress }
                        Default { "Unknown" }
                    }
                    "Intercluster" = switch ([string]::IsNullOrEmpty($NodeInterClusterAddress)) {
                        $true { "Unknown" }
                        $false { $NodeInterClusterAddress }
                        Default { "Unknown" }
                    }
                }
            }

            if ($ClusterInfo) {
                $ClusterNodeObj = Add-DiaHTMLNodeTable -ImagesObj $Images -inputObject $NodeSum.Node -Align "Center" -iconType "Ontap_Node" -columnSize $NodeSumColumnSize -IconDebug $IconDebug -MultiIcon -AditionalInfo $NodeAdditionalInfo -Subgraph -SubgraphIconType "Ontap_Node_Icon" -SubgraphLabel $ClusterInfo.ClusterName -SubgraphLabelPos "top" -SubgraphTableStyle "dashed,rounded" -TableBorderColor "#71797E" -TableBorder "0" -SubgraphLabelFontsize 22 -fontSize 18
            }

            if ($ClusterNodeObj) {
                $ClusterMgmtObj = Add-DiaHTMLSubGraph -ImagesObj $Images -TableArray $ClusterNodeObj -Align 'Right' -IconDebug $IconDebug -Label "Management: $($ClusterInfo.NcController)" -LabelPos 'down' -TableStyle "dashed,rounded" -TableBorderColor $Edgecolor -TableBorder "1" -columnSize 1 -fontSize 12

                if ($ClusterMgmtObj) {
                    Node SourceCluster @{Label = $ClusterMgmtObj; shape = 'plain'; fillColor = 'transparent'; fontsize = 14 }
                } else {
                    Write-PScriboMessage -IsWarning "Unable to create Cluster Node. No Cluster Management Object found."
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning $_.Exception.Message
        }

        try {
            $VserverPeers = Get-NcVserverPeer -Controller $Array
            $VserversPeerInfo = @()
            if ($VserverPeers) {
                $Index = $VserverPeersColors.Count - 1
                foreach ($VserverPeer in $VserverPeers) {
                    $VserversPeerInfo += [PSCustomObject][ordered]@{
                        "SourceCluster" = $ClusterInfo.ClusterName
                        "SourceVserver" = $VserverPeer.Vserver
                        "RemoteCluster" = $VserverPeer.PeerCluster
                        "RemoteVserver" = $VserverPeer.PeerVserver
                        "Color" = Get-RandomPastelColorHex
                        "SourceAdditionalInfo" = [PSCustomObject][ordered]@{
                            "Peer Vserver" = $VserverPeer.PeerVserver
                            "Peer Cluster" = $VserverPeer.PeerCluster
                            "Applications" = $VserverPeer.Applications -join ", "
                        }
                        "DestinationAdditionalInfo" = [PSCustomObject][ordered]@{
                            "Peer Vserver" = $VserverPeer.Vserver
                            "Peer Cluster" = $ClusterInfo.ClusterName
                            "Applications" = $VserverPeer.Applications -join ", "
                        }
                    }
                }
            }

            $VserverPeerObj = @()

            $VserverPeerObj = foreach ($VserverPeer in $VserversPeerInfo) {
                Add-DiaHTMLNodeTable -ImagesObj $Images -inputObject $VserverPeer.SourceVserver -Align "Center" -iconType "Ontap_SVM" -columnSize 1 -IconDebug $IconDebug -MultiIcon -AditionalInfo  $VserverPeer.SourceAdditionalInfo -SubgraphTableStyle "dashed,rounded" -TableBorderColor "#71797E" -TableBorder 1 -fontSize 18 -CellBackgroundColor $VserverPeer.Color
            }

            if ($VserverPeerObj.Count -eq 1) {
                $VserverPeerObjColumnSize = 1
            } elseif ($ColumnSize) {
                $VserverPeerObjColumnSize = $ColumnSize
            } else {
                $VserverPeerObjColumnSize = $VserverPeerObj.Count
            }

            $VserverPeerSubGraphObj = Add-DiaHTMLSubGraph -ImagesObj $Images -TableArray $VserverPeerObj -Align 'Center' -IconDebug $IconDebug -Label "Source Storage VMs" -LabelPos 'top' -TableStyle "dashed,rounded" -TableBorderColor $Edgecolor -TableBorder "1" -columnSize $VserverPeerObjColumnSize -fontSize 18 -IconType "Ontap_SVM_Icon"

            if ($VserverPeerSubGraphObj) {
                Node SourceVservers @{Label = $VserverPeerSubGraphObj; shape = 'plain'; fillColor = 'transparent'; fontsize = 14 }
                Edge -From SourceVservers -To SourceCluster @{minlen = 2; color = '#71797E'; style = 'filled'; arrowhead = 'box'; arrowtail = 'box' }
                Rank SourceVservers, SourceCluster
            }
        } catch {
            Write-PScriboMessage -IsWarning $_.Exception.Message
        }

        try {
            $ClusterReplicaInfos = Get-NcClusterPeer -Controller $Array
            $Ranks = @()
            foreach ($ClusterReplicaInfo in $ClusterReplicaInfos) {
                $NodeReplicaSum = $ClusterReplicaInfo.RemoteClusterNodes

                if ($NodeReplicaSum.Count -eq 1) {
                    $NodeSumColumnSize = 1
                } elseif ($ColumnSize) {
                    $NodeSumColumnSize = $ColumnSize
                } else {
                    $NodeSumColumnSize = $NodeReplicaSum.Count
                }

                $Num = 0

                $NodeAdditionalInfo = @()

                foreach ($Node in $NodeReplicaSum) {

                    $NodeName = $Node
                    $NodeMgmtAddress = $ClusterReplicaInfo.NcController

                    $NodeAdditionalInfo += [PSCustomObject][ordered]@{
                        "Intercluster" = switch ([string]::IsNullOrEmpty($ClusterReplicaInfo.ActiveAddresses)) {
                            $true { "Unknown" }
                            $false {
                                & {
                                    if ($ClusterReplicaInfo.ActiveAddresses.Count -gt 1) {
                                        ($ClusterReplicaInfo.ActiveAddresses | Sort-Object)[$Num]
                                    } else {
                                        $ClusterReplicaInfo.ActiveAddresses
                                    }
                                }
                            }
                            Default { "Unknown" }
                        }
                    }
                    $Num++
                }

                if ($ClusterReplicaInfo) {
                    try {
                        $ClusterReplicaNodeObj = Add-DiaHTMLNodeTable -ImagesObj $Images -inputObject $NodeReplicaSum -Align "Center" -iconType "Ontap_Node" -columnSize $NodeSumColumnSize -IconDebug $IconDebug -MultiIcon -AditionalInfo $NodeAdditionalInfo -Subgraph -SubgraphIconType "Ontap_Node_Icon" -SubgraphLabel $ClusterReplicaInfo.ClusterName -SubgraphLabelPos "top" -SubgraphTableStyle "dashed,rounded" -TableBorderColor "#71797E" -TableBorder "1" -SubgraphLabelFontsize 22 -fontSize 18
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }

                if ($ClusterReplicaNodeObj) {
                    if ($ClusterReplicaNodeObj) {
                        $RemoteClusterName = Remove-SpecialChar -String $ClusterReplicaInfo.ClusterName -SpecialChars '\-_'
                        Node $RemoteClusterName @{Label = $ClusterReplicaNodeObj; shape = 'plain'; fillColor = 'transparent'; fontsize = 14 }
                        $Ranks += $RemoteClusterName
                    } else {
                        Write-PScriboMessage -IsWarning "Unable to create Cluster Replication Node. No Cluster Management Object found."
                    }
                }

                if ($ClusterReplicaNodeObj) {
                    Edge -From SourceCluster:e -To $RemoteClusterName @{minlen = 3; color = '#71797E'; style = 'filled'; arrowhead = 'box'; arrowtail = 'box' }
                }

                try {
                    $PeerVserverPeerObj = @()

                    $PeerVserverPeerObj = foreach ($VserversPeer in ($VserversPeerInfo | Where-Object { $_.RemoteCluster -eq $ClusterReplicaInfo.ClusterName })) {
                        Add-DiaHTMLNodeTable -ImagesObj $Images -inputObject $VserversPeer.RemoteVserver -Align "Center" -iconType "Ontap_SVM" -columnSize 1 -IconDebug $IconDebug -MultiIcon -AditionalInfo $VserversPeer.DestinationAdditionalInfo -SubgraphTableStyle "dashed,rounded" -TableBorderColor "#71797E" -TableBorder "1" -SubgraphLabelFontsize 22 -fontSize 18 -CellBackgroundColor $VserversPeer.Color
                    }

                    if ($PeerVserverPeerObj.Count -eq 1) {
                        $PeerVserverPeerObjColumnSize = 1
                    } elseif ($ColumnSize) {
                        $PeerVserverPeerObjColumnSize = $ColumnSize
                    } else {
                        $PeerVserverPeerObjColumnSize = $PeerVserverPeerObj.Count
                    }

                    $PeerVserverPeerSubGraphObj = Add-DiaHTMLSubGraph -ImagesObj $Images -TableArray $PeerVserverPeerObj -Align 'Center' -IconDebug $IconDebug -Label "Peer Storage VMs" -LabelPos 'top' -TableStyle "dashed,rounded" -TableBorderColor $Edgecolor -TableBorder "1" -columnSize $PeerVserverPeerObjColumnSize -fontSize 18 -IconType "Ontap_SVM_Icon"

                    if ($PeerVserverPeerSubGraphObj) {
                        Node "$($RemoteClusterName)PeerVservers" @{Label = $PeerVserverPeerSubGraphObj; shape = 'plain'; fillColor = 'transparent'; fontsize = 14 }
                        Edge -From $RemoteClusterName -To "$($RemoteClusterName)PeerVservers" @{minlen = 2; color = '#71797E'; style = 'filled'; arrowhead = 'box'; arrowtail = 'box' }
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