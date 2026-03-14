function Get-AbrOntapNodeNetworkDiagram {
    <#
    .SYNOPSIS
        Used by As Built Report to built NetApp ONTAP node network diagram
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
        Write-PScriboMessage 'Generating Node Network Diagram for NetApp ONTAP.'
        # Set the root path for icons
        $RootPath = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
        [System.IO.FileInfo]$IconPath = Join-Path $RootPath 'icons'

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

            try {

                $HAObject = @()

                $NodeAdditionalInfo = @()
                $NetPortInfo = @()
                $NetLifsInfo = @()
                $NetVlanInfo = @()

                foreach ($Node in $NodeSum) {
                    $ClusterHa = Get-NcClusterHa -Node $Node.Node -Controller $Array

                    $NodeMgmtAddress = Get-NcNetInterface -Controller $Array | Where-Object { $_.Role -eq 'node_mgmt' -and $_.HomeNode -eq $Node.Node } | Select-Object -ExpandProperty Address

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
                                $false { $NodeMgmtAddress -join ', ' }
                                default { 'Unknown' }
                            }
                        }
                    }

                    $NodePorts = Get-NcNetPort -Controller $Array | Where-Object { $_.Node -eq $Node.Node }
                    foreach ($NodePort in $NodePorts) {
                        $NetPortInfo += [PSCustomObject][ordered]@{
                            'NodeName' = $NodePort.Node
                            'PortName' = $NodePort.Name
                            'PortType' = $NodePort.PortType
                            'IsParentVlan' = & { if (Get-NcNetPortVlan -Controller $Array -ParentInterface $NodePort.Name -Node $Node.Node) { $true } else { $false } }
                            'AdditionalInfo' = [PSCustomObject][ordered]@{
                                'Health' = $NodePort.HealthStatus
                                'Broadcast Domain' = switch ([string]::IsNullOrEmpty($NodePort.BroadcastDomain)) {
                                    $true { 'Unknown' }
                                    $false { $NodePort.BroadcastDomain }
                                    default { 'Unknown' }
                                }
                                'Ifgrp Port' = switch ([string]::IsNullOrEmpty($NodePort.IfgrpPort)) {
                                    $true { 'None' }
                                    $false { $NodePort.IfgrpPort }
                                    default { 'Unknown' }
                                }
                                'Ipspace' = $NodePort.IpSpace
                                'Link Status' = switch ($NodePort.LinkStatus) {
                                    'up' { 'Up' }
                                    'down' { 'Down' }
                                    default { 'Unknown' }
                                }
                                'Mac' = $NodePort.MacAddress
                                'Mtu' = $NodePort.Mtu
                            }
                        }
                    }

                    $NodeLifs = Get-NcNetInterface -Controller $Array | Where-Object { $_.HomeNode -eq $Node.Node -and $_.DataProtocols -ne 'fcp' }
                    foreach ($NodeLif in $NodeLifs) {
                        $NetLifsInfo += [PSCustomObject][ordered]@{
                            'NodeName' = $NodeLif.HomeNode
                            'InterfaceName' = $NodeLif.InterfaceName
                            'HomeNode' = $NodeLif.HomeNode
                            'HomePort' = $NodeLif.HomePort
                            'CurrentNode' = $NodeLif.CurrentNode
                            'CurrentPort' = $NodeLif.CurrentPort
                            'AdditionalInfo' = [PSCustomObject][ordered]@{
                                'IP' = $NodeLif.Address
                                'Netmask' = $NodeLif.Netmask
                                'Is Home?' = switch ($NodeLif.IsHome) {
                                    $true { 'Yes' }
                                    $false { 'No' }
                                    default { 'Unknown' }
                                }
                                'Status' = switch ($NodeLif.AdministrativeStatus) {
                                    'up' { 'Up' }
                                    'down' { 'Down' }
                                    default { 'Unknown' }
                                }
                                'Role' = switch ([string]::IsNullOrEmpty($NodeLif.Role)) {
                                    $true { 'Unknown' }
                                    $false { $TextInfo.ToTitleCase($NodeLif.Role) }
                                    default { 'Unknown' }
                                }
                            }
                        }
                    }

                    $NodeVlans = Get-NcNetPortVlan -Node $Node.Node -Controller $Array
                    foreach ($NodeVlan in $NodeVlans) {
                        $NetVlanInfo += [PSCustomObject][ordered]@{
                            'NodeName' = $NodeVlan.Node
                            'InterfaceName' = $NodeVlan.InterfaceName
                            'ParentInterface' = $NodeVlan.ParentInterface
                            'VlanID' = $NodeVlan.VlanID
                        }
                    }
                }

                # Cluster Network Diagram
                $ClusterNetwork = Add-DiaNodeImage -Name 'ClusterSwitch1' -ImagesObj $Images -IconType 'Ontap_Cluster_Network' -IconDebug $IconDebug -TableBackgroundColor '#a1e3fd'

                Add-DiaHtmlSubGraph -Name 'ClusterNetwork' -TableArray $ClusterNetwork -Label 'Cluster Network' -LabelPos top -ImagesObj $Images -IconDebug $IconDebug -NodeObject -TableBorder 1 -FontSize 20 -TableBorderColor '#71797E' -TableStyle 'rounded,dashed' -FontColor 'darkblue' -FontBold -FontName 'Segoe Ui Bold' -TableBackgroundColor '#a1e3fd'

                foreach ($Node in $NodeAdditionalInfo) {

                    # Ontap System Node
                    Add-DiaNodeIcon -Name $Node.NodeName -ImagesObj $Images -Align 'Center' -IconType 'Ontap_Node' -IconDebug $IconDebug -AditionalInfo $Node.AdditionalInfo -TableBorder 1 -FontSize 18 -NodeObject -TableBorderColor '#71797E' -TableStyle 'rounded,dashed'


                    if ($NetPortInfo) {
                        # Cluster Network Ports
                        $ClusterPortObj = @()
                        foreach ($Port in ($NetPortInfo | Where-Object { $_.Nodename -eq $Node.Nodename -and $_.AdditionalInfo.'Broadcast Domain' -eq 'Cluster' })) {

                            $PerPortLifs = @()
                            foreach ($Lif in ($NetLifsInfo | Where-Object { $_.NodeName -eq $Node.Nodename -and $_.CurrentPort -eq $Port.PortName })) {
                                $PerPortLifs += if ($Lif.AdditionalInfo.'Is Home?' -eq 'Yes') {
                                    Add-DiaNodeIcon -Name $Lif.InterfaceName -ImagesObj $Images -Align 'Center' -IconType 'Ontap_Network_Nic' -IconDebug $IconDebug -AditionalInfo $Lif.AdditionalInfo -ImageSizePercent 50 -IconPath $IconPath -FontSize 12
                                } else {
                                    Add-DiaNodeIcon -Name $Lif.InterfaceName -ImagesObj $Images -Align 'Center' -IconType 'Ontap_Network_Nic' -IconDebug $IconDebug -AditionalInfo $Lif.AdditionalInfo -ImageSizePercent 50 -IconPath $IconPath -FontSize 12 -TableBackgroundColor '#ffcccc' -CellBackgroundColor '#ffcccc'
                                }
                            }

                            if (-not $PerPortLifs) {
                                $PerPortLifs = Add-DiaNodeText -Name "$($Port.NodeName)_$($Port.PortName)_NoLifs" -Text 'No LIFs Assigned' -IconDebug $IconDebug -FontSize 14 -FontBold
                            }

                            if ($PerPortLifs.Count -eq 1) { $PerPortLifsColumnSize = 1 } elseif ($Options.DiagramColumnSize) { $PerPortLifsColumnSize = $Options.DiagramColumnSize } else { $PerPortLifsColumnSize = $PerPortLifs.Count }

                            $ClusterPortObj += Add-DiaHtmlSubGraph -Name "$($Port.NodeName)$($Port.PortName)_Lifs" -TableArray $PerPortLifs -ImagesObj $Images -IconDebug $IconDebug -TableBorder 1 -Label $Port.PortName -LabelPos top -TableStyle 'rounded,dashed' -TableBorderColor '#71797E' -FontName 'Segoe Ui Bold' -ColumnSize $PerPortLifsColumnSize
                        }

                        if ($ClusterPortObj.Count -eq 1) { $ClusterPortObjColumnSize = 1 } elseif ($Options.DiagramColumnSize) { $ClusterPortObjColumnSize = $Options.DiagramColumnSize } else { $ClusterPortObjColumnSize = $ClusterPortObj.Count }

                        Add-DiaHtmlSubGraph -Name "$($Port.NodeName)ClusterPorts" -TableArray $ClusterPortObj -ImagesObj $Images -IconDebug $IconDebug -TableBorder 1 -IconType 'Ontap_Network_Port' -Label 'Cluster Network Ports' -LabelPos top -TableStyle 'rounded,dashed' -TableBorderColor '#71797E' -FontName 'Segoe Ui Bold' -ColumnSize $ClusterPortObjColumnSize -NodeObject

                        Add-DiaNodeEdge -From 'ClusterNetwork' -To "$($Port.NodeName)ClusterPorts" -EdgeColor $Edgecolor -EdgeStyle 'dashed' -EdgeThickness 1 -Arrowhead 'box' -Arrowtail 'box' -EdgeLabelFontColor $Fontcolor -EdgeLabelFontSize 12

                        Add-DiaNodeEdge -From "$($Port.NodeName)ClusterPorts" -To $Node.NodeName -EdgeColor $Edgecolor -EdgeStyle 'dashed' -EdgeThickness 1 -Arrowhead 'box' -Arrowtail 'box' -EdgeLabelFontColor $Fontcolor -EdgeLabelFontSize 12 -EdgeLength 1

                        # Non-IFGRP Ports without Vlan Interfces
                        foreach ($Port in ($NetPortInfo | Where-Object { $_.Nodename -eq $Node.Nodename -and $_.AdditionalInfo.'Broadcast Domain' -ne 'Cluster' -and $_.AdditionalInfo.'Ifgrp Port' -in @('None', 'Unknown') -and $_.PortName -notmatch 'a0' -and $_.PortType -ne 'vlan' -and $_.IsParentVlan -eq $false })) {
                            $PerPortLifs = @()
                            foreach ($Lif in ($NetLifsInfo | Where-Object { $_.CurrentNode -eq $Node.Nodename -and $_.CurrentPort -eq $Port.PortName })) {
                                $PerPortLifs += if ($Lif.AdditionalInfo.'Is Home?' -eq 'Yes') {
                                    Add-DiaNodeIcon -Name $Lif.InterfaceName -ImagesObj $Images -Align 'Center' -IconType 'Ontap_Network_Nic' -IconDebug $IconDebug -AditionalInfo $Lif.AdditionalInfo -ImageSizePercent 50 -IconPath $IconPath -FontSize 12
                                } else {
                                    Add-DiaNodeIcon -Name $Lif.InterfaceName -ImagesObj $Images -Align 'Center' -IconType 'Ontap_Network_Nic' -IconDebug $IconDebug -AditionalInfo $Lif.AdditionalInfo -ImageSizePercent 50 -IconPath $IconPath -FontSize 12 -TableBackgroundColor '#ffcccc' -CellBackgroundColor '#ffcccc'
                                }
                            }

                            if (-not $PerPortLifs) {
                                $PerPortLifs = Add-DiaNodeText -Name "$($Port.NodeName)_$($Port.PortName)_NoLifs" -Text 'No LIFs Assigned' -IconDebug $IconDebug -FontSize 14 -FontBold
                            }

                            if ($PerPortLifs.Count -eq 1) { $PerPortLifsColumnSize = 1 } elseif ($Options.DiagramColumnSize) { $PerPortLifsColumnSize = $Options.DiagramColumnSize } else { $PerPortLifsColumnSize = $PerPortLifs.Count }

                            Add-DiaHtmlSubGraph -Name "$($Port.NodeName)$($Port.PortName)_Lifs" -TableArray $PerPortLifs -ImagesObj $Images -IconDebug $IconDebug -TableBorder 1 -IconType 'Ontap_Network_Port' -Label $Port.PortName -LabelPos top -TableStyle 'rounded,dashed' -TableBorderColor '#71797E' -FontName 'Segoe Ui Bold' -NodeObject -ColumnSize $PerPortLifsColumnSize

                            Add-DiaNodeEdge -From $Node.NodeName -To "$($Port.NodeName)$($Port.PortName)_Lifs" -EdgeColor $Edgecolor -EdgeStyle 'dashed' -EdgeThickness 1 -Arrowhead 'box' -Arrowtail 'box' -EdgeLabelFontColor $Fontcolor -EdgeLabelFontSize 12 -EdgeLength 1
                        }

                        # IFGRP Ports (Link Aggregation Groups) with member ports and LIFs
                        foreach ($IfgrpPort in ($NetPortInfo | Where-Object { $_.Nodename -eq $Node.Nodename -and $_.PortType -eq 'ifgrp' })) {
                            $IfgrpPortLifs = @()
                            foreach ($Lif in ($NetLifsInfo | Where-Object { $_.CurrentNode -eq $Node.Nodename -and $_.CurrentPort -eq $IfgrpPort.PortName })) {
                                $IfgrpPortLifs += if ($Lif.AdditionalInfo.'Is Home?' -eq 'Yes') {
                                    Add-DiaNodeIcon -Name $Lif.InterfaceName -ImagesObj $Images -Align 'Center' -IconType 'Ontap_Network_Nic' -IconDebug $IconDebug -AditionalInfo $Lif.AdditionalInfo -ImageSizePercent 50 -IconPath $IconPath -FontSize 12
                                } else {
                                    Add-DiaNodeIcon -Name $Lif.InterfaceName -ImagesObj $Images -Align 'Center' -IconType 'Ontap_Network_Nic' -IconDebug $IconDebug -AditionalInfo $Lif.AdditionalInfo -ImageSizePercent 50 -IconPath $IconPath -FontSize 12 -TableBackgroundColor '#ffcccc' -CellBackgroundColor '#ffcccc'
                                }
                            }

                            if (-not $IfgrpPortLifs) {
                                $IfgrpPortLifs = Add-DiaNodeText -Name "$($IfgrpPort.NodeName)_$($IfgrpPort.PortName)_NoLifs" -Text 'No LIFs Assigned' -IconDebug $IconDebug -FontSize 14 -FontBold
                            }

                            if ($IfgrpPortLifs.Count -eq 1) { $IfgrpPortLifsColumnSize = 1 } elseif ($Options.DiagramColumnSize) { $IfgrpPortLifsColumnSize = $Options.DiagramColumnSize } else { $IfgrpPortLifsColumnSize = $IfgrpPortLifs.Count }

                            # Member physical ports of this IFGRP
                            $MemberPortItems = @()
                            foreach ($MemberPort in ($NetPortInfo | Where-Object { $_.Nodename -eq $Node.Nodename -and $_.AdditionalInfo.'Ifgrp Port' -eq $IfgrpPort.PortName })) {
                                $MemberPortItems += Add-DiaNodeText -Name "$($MemberPort.NodeName)_$($MemberPort.PortName)_MemberPort" -Text $MemberPort.PortName -IconDebug $IconDebug -FontSize 12
                            }

                            $IfgrpPortObj = @()
                            if ($MemberPortItems) {
                                if ($MemberPortItems.Count -eq 1) { $MemberPortColumnSize = 1 } elseif ($Options.DiagramColumnSize) { $MemberPortColumnSize = $Options.DiagramColumnSize } else { $MemberPortColumnSize = $MemberPortItems.Count }
                                $IfgrpPortObj += Add-DiaHtmlSubGraph -Name "$($IfgrpPort.NodeName)$($IfgrpPort.PortName)_Members" -TableArray $MemberPortItems -ImagesObj $Images -IconDebug $IconDebug -TableBorder 1 -Label 'Member Ports' -LabelPos top -TableStyle 'rounded,dashed' -TableBorderColor '#71797E' -FontName 'Segoe Ui Bold' -ColumnSize $MemberPortColumnSize
                            }

                            $IfgrpPortObj += Add-DiaHtmlSubGraph -Name "$($IfgrpPort.NodeName)$($IfgrpPort.PortName)_IfgrpLifs" -TableArray $IfgrpPortLifs -ImagesObj $Images -IconDebug $IconDebug -TableBorder 1 -Label $IfgrpPort.PortName -LabelPos top -TableStyle 'rounded,dashed' -TableBorderColor '#71797E' -FontName 'Segoe Ui Bold' -ColumnSize $IfgrpPortLifsColumnSize

                            if ($IfgrpPortObj.Count -eq 1) { $IfgrpPortObjColumnSize = 1 } elseif ($Options.DiagramColumnSize) { $IfgrpPortObjColumnSize = $Options.DiagramColumnSize } else { $IfgrpPortObjColumnSize = $IfgrpPortObj.Count }

                            Add-DiaHtmlSubGraph -Name "$($IfgrpPort.NodeName)$($IfgrpPort.PortName)_Ifgrp" -TableArray $IfgrpPortObj -ImagesObj $Images -IconDebug $IconDebug -TableBorder 1 -IconType 'Ontap_Network_Port' -Label "$($IfgrpPort.PortName) (IFGRP)" -LabelPos top -TableStyle 'rounded,dashed' -TableBorderColor '#71797E' -FontName 'Segoe Ui Bold' -NodeObject -ColumnSize $IfgrpPortObjColumnSize

                            Add-DiaNodeEdge -From $Node.NodeName -To "$($IfgrpPort.NodeName)$($IfgrpPort.PortName)_Ifgrp" -EdgeColor $Edgecolor -EdgeStyle 'dashed' -EdgeThickness 1 -Arrowhead 'box' -Arrowtail 'box' -EdgeLabelFontColor $Fontcolor -EdgeLabelFontSize 12 -EdgeLength 1
                        }

                        # VLAN Interface Ports with LIFs
                        if ($NetVlanInfo) {
                            foreach ($VlanPort in ($NetVlanInfo | Where-Object { $_.NodeName -eq $Node.Nodename })) {
                                $VlanPortLifs = @()
                                foreach ($Lif in ($NetLifsInfo | Where-Object { $_.CurrentNode -eq $Node.Nodename -and $_.CurrentPort -eq $VlanPort.InterfaceName })) {
                                    $VlanPortLifs += if ($Lif.AdditionalInfo.'Is Home?' -eq 'Yes') {
                                        Add-DiaNodeIcon -Name $Lif.InterfaceName -ImagesObj $Images -Align 'Center' -IconType 'Ontap_Network_Nic' -IconDebug $IconDebug -AditionalInfo $Lif.AdditionalInfo -ImageSizePercent 50 -IconPath $IconPath -FontSize 12
                                    } else {
                                        Add-DiaNodeIcon -Name $Lif.InterfaceName -ImagesObj $Images -Align 'Center' -IconType 'Ontap_Network_Nic' -IconDebug $IconDebug -AditionalInfo $Lif.AdditionalInfo -ImageSizePercent 50 -IconPath $IconPath -FontSize 12 -TableBackgroundColor '#ffcccc' -CellBackgroundColor '#ffcccc'
                                    }
                                }

                                if (-not $VlanPortLifs) {
                                    $VlanPortLifs = Add-DiaNodeText -Name "$($VlanPort.NodeName)_$($VlanPort.InterfaceName)_NoLifs" -Text 'No LIFs Assigned' -IconDebug $IconDebug -FontSize 14 -FontBold
                                }

                                if ($VlanPortLifs.Count -eq 1) { $VlanPortLifsColumnSize = 1 } elseif ($Options.DiagramColumnSize) { $VlanPortLifsColumnSize = $Options.DiagramColumnSize } else { $VlanPortLifsColumnSize = $VlanPortLifs.Count }

                                Add-DiaHtmlSubGraph -Name "$($VlanPort.NodeName)$($VlanPort.InterfaceName)_Vlan" -TableArray $VlanPortLifs -ImagesObj $Images -IconDebug $IconDebug -TableBorder 1 -IconType 'Ontap_Network_Port' -Label "$($VlanPort.InterfaceName) (VLAN $($VlanPort.VlanID))" -LabelPos top -TableStyle 'rounded,dashed' -TableBorderColor '#71797E' -FontName 'Segoe Ui Bold' -NodeObject -ColumnSize $VlanPortLifsColumnSize

                                Add-DiaNodeEdge -From $Node.NodeName -To "$($VlanPort.NodeName)$($VlanPort.InterfaceName)_Vlan" -EdgeColor $Edgecolor -EdgeStyle 'dashed' -EdgeThickness 1 -Arrowhead 'box' -Arrowtail 'box' -EdgeLabelFontColor $Fontcolor -EdgeLabelFontSize 12 -EdgeLength 1
                            }
                        }
                    }
                }

                foreach ($HA in $HAObject) {
                    if ($HA.Partner) {
                        Add-DiaNodeEdge -From $HA.Name -To $HA.Partner -EdgeColor $Edgecolor -EdgeStyle 'solid' -EdgeThickness 2 -Arrowhead 'box' -Arrowtail 'box' -EdgeLabel "HA: $($HA.HAState)" -EdgeLabelFontColor $Fontcolor -EdgeLabelFontSize 16 -EdgeLength 3 -TailPort $HA.Name -HeadPort $HA.Partner
                        Rank $HA.Name, $HA.Partner
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