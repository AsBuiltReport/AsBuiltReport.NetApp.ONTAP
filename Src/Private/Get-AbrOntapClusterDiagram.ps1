function Get-AbrOntapClusterDiagram {
    <#
    .SYNOPSIS
        Used by As Built Report to built NetApp ONTAP cluster diagram
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
        Write-PScriboMessage 'Generating Cluster Diagram for NetApp ONTAP.'
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
                SubGraph ClusterInfo -Attributes @{Label = "Management: $($ClusterInfo.NcController)"; fontsize = 16; penwidth = 1.5; labelloc = 'b'; labeljust = 'r'; style = 'dashed,rounded'; color = 'transparent' } {
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

                        foreach ($Node in $NodeSum) {
                            $ClusterHa = try { Get-NcClusterHa -Node $Node.Node -Controller $Array } catch { Write-PScriboMessage -IsWarning $_.Exception.Message }

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
                                        $false { $NodeMgmtAddress -join ',' }
                                        default { 'Unknown' }
                                    }
                                    'Intercluster' = switch ([string]::IsNullOrEmpty($NodeInterClusterAddress)) {
                                        $true { 'Unknown' }
                                        $false { $NodeInterClusterAddress }
                                        default { 'Unknown' }
                                    }
                                }
                            }
                        }

                        # Build a flat list of all graphviz node names for edge creation
                        $AllNodeNames = @()
                        foreach ($HA in $HAObject) {
                            $AllNodeNames += Remove-SpecialChar -String $HA.Name -SpecialChars '\-_'
                            if ($HA.Partner) {
                                $AllNodeNames += Remove-SpecialChar -String $HA.Partner -SpecialChars '\-_'
                            }
                        }

                        # Cluster Network switch
                        $ClusterNetworkImage = Add-DiaNodeImage -Name 'ClusterSwitch1' -ImagesObj $Images -IconType 'Ontap_Cluster_Network' -IconDebug $IconDebug -TableBackgroundColor '#a1e3fd'
                        Add-DiaHtmlSubGraph -Name 'ClusterNetwork' -TableArray $ClusterNetworkImage -Label 'Cluster Network' -LabelPos top -ImagesObj $Images -IconDebug $IconDebug -NodeObject -TableBorder 1 -FontSize 16 -TableBorderColor '#71797E' -TableStyle 'rounded,dashed' -FontColor 'darkblue' -FontBold -FontName 'Segoe Ui Bold' -TableBackgroundColor '#a1e3fd'

                        if ($HAObject.Name -and $HAObject.Partner) {
                            foreach ($HA in $HAObject) {
                                $HAClusterName = Remove-SpecialChar -String "HA$($HA.Name)$($HA.Partner)" -SpecialChars '\-_'
                                SubGraph $HAClusterName -Attributes @{Label = 'HA Pair'; fontsize = 16; penwidth = 1.5; labelloc = 't'; style = 'dashed,rounded'; color = 'gray'; labeljust = 'c' } {

                                    $HAName = Remove-SpecialChar -String $HA.Name -SpecialChars '\-_'
                                    $HAPartner = Remove-SpecialChar -String $HA.Partner -SpecialChars '\-_'

                                    Node $HAName @{Label = Add-DiaNodeIcon -Name $HA.Name -AditionalInfo ($NodeAdditionalInfo | Where-Object { $_.NodeName -eq $HA.Name }).AdditionalInfo -ImagesObj $Images -IconType 'Ontap_Node' -Align 'Center' -IconDebug $IconDebug -FontSize 18; shape = 'plain'; fillColor = 'transparent'; fontsize = 14 }

                                    Node $HAPartner @{Label = Add-DiaNodeIcon -Name $HA.Partner -AditionalInfo ($NodeAdditionalInfo | Where-Object { $_.NodeName -eq $HA.Partner }).AdditionalInfo -ImagesObj $Images -IconType 'Ontap_Node' -Align 'Center' -IconDebug $IconDebug -FontSize 18; shape = 'plain'; fillColor = 'transparent'; fontsize = 14 }

                                    Rank $HAName, $HAPartner

                                    Add-DiaNodeEdge -From $HAName -To $HAPartner -EdgeColor $Edgecolor -EdgeStyle 'solid' -EdgeThickness 2 -Arrowhead 'box' -Arrowtail 'box' -EdgeLabel "HA: $($HA.HAState)" -EdgeLabelFontColor $Fontcolor -EdgeLabelFontSize 16 -EdgeLength 2
                                }
                            }
                        } else {
                            foreach ($HA in $HAObject) {
                                $HAClusterName = Remove-SpecialChar -String "HA$($HA.Name)" -SpecialChars '\-_'
                                SubGraph $HAClusterName -Attributes @{Label = 'Single Node Cluster'; fontsize = 16; penwidth = 1.5; labelloc = 't'; style = 'dashed,rounded'; color = 'gray'; labeljust = 'c' } {
                                    $HAName = Remove-SpecialChar -String $HA.Name -SpecialChars '\-_'
                                    Node $HAName @{Label = Add-DiaNodeIcon -Name $HA.Name -AditionalInfo ($NodeAdditionalInfo | Where-Object { $_.NodeName -eq $HA.Name }).AdditionalInfo -ImagesObj $Images -IconType 'Ontap_Node' -Align 'Center' -IconDebug $IconDebug -FontSize 18; shape = 'plain'; fillColor = 'transparent'; fontsize = 14 }
                                }
                            }
                        }

                        # Management Network switch
                        $MgmtNetworkImage = Add-DiaNodeImage -Name 'MgmtSwitch1' -ImagesObj $Images -IconType 'Ontap_Cluster_Network' -IconDebug $IconDebug -TableBackgroundColor '#d5e8d4'
                        Add-DiaHtmlSubGraph -Name 'ManagementNetwork' -TableArray $MgmtNetworkImage -Label 'Management Network' -LabelPos top -ImagesObj $Images -IconDebug $IconDebug -NodeObject -TableBorder 1 -FontSize 16 -TableBorderColor '#71797E' -TableStyle 'rounded,dashed' -FontColor 'darkgreen' -FontBold -FontName 'Segoe Ui Bold' -TableBackgroundColor '#d5e8d4'

                        # Data Network switch
                        $DataNetworkImage = Add-DiaNodeImage -Name 'DataSwitch1' -ImagesObj $Images -IconType 'Ontap_Cluster_Network' -IconDebug $IconDebug -TableBackgroundColor '#dae8fc'
                        Add-DiaHtmlSubGraph -Name 'DataNetwork' -TableArray $DataNetworkImage -Label 'Data Network' -LabelPos top -ImagesObj $Images -IconDebug $IconDebug -NodeObject -TableBorder 1 -FontSize 16 -TableBorderColor '#71797E' -TableStyle 'rounded,dashed' -FontColor 'darkblue' -FontBold -FontName 'Segoe Ui Bold' -TableBackgroundColor '#dae8fc'

                        # Connect all nodes to the network infrastructure elements
                        foreach ($NodeName in $AllNodeNames) {
                            Add-DiaNodeEdge -From 'ClusterNetwork' -To $NodeName -EdgeColor '#5B9BD5' -EdgeStyle 'dashed' -Arrowhead 'none' -Arrowtail 'none' -EdgeLabelFontColor $Fontcolor -EdgeLabelFontSize 10 -EdgeLength 2 -EdgeThickness 3
                            Add-DiaNodeEdge -From 'ManagementNetwork' -To $NodeName -EdgeColor $Edgecolor -EdgeStyle 'dashed' -Arrowhead 'none' -Arrowtail 'none' -EdgeLabelFontColor $Fontcolor -EdgeLabelFontSize 10 -EdgeLength 2 -EdgeThickness 3
                            Add-DiaNodeEdge -From $NodeName -To 'DataNetwork' -EdgeColor '#70AD47' -EdgeStyle 'dashed' -Arrowhead 'none' -Arrowtail 'none' -EdgeLabelFontColor $Fontcolor -EdgeLabelFontSize 10 -EdgeLength 2 -EdgeThickness 3
                        }

                        # Data Network - Per Broadcast Domain Information
                        try {
                            $DataBroadcastDomains = Get-NcNetPortBroadcastDomain -Controller $Array | Where-Object { $_.BroadcastDomain -ne 'Cluster' }

                            if ($DataBroadcastDomains) {
                                foreach ($BDomain in $DataBroadcastDomains) {
                                    $BDomainSafeName = Remove-SpecialChar -String $BDomain.BroadcastDomain -SpecialChars '\-_:'

                                    $PortTextItems = @()
                                    if ($BDomain.Ports) {
                                        foreach ($PortMember in $BDomain.Ports) {
                                            $PortSafeName = Remove-SpecialChar -String $PortMember -SpecialChars '\-_:'
                                            $PortTextItems += Add-DiaNodeText -Name "BD${BDomainSafeName}${PortSafeName}" -Text $PortMember -IconDebug $IconDebug -FontSize 12
                                        }
                                    } else {
                                        $PortTextItems += Add-DiaNodeText -Name "BD${BDomainSafeName}NoPorts" -Text 'No Ports Assigned' -IconDebug $IconDebug -FontSize 12
                                    }

                                    Add-DiaHtmlSubGraph -Name "${BDomainSafeName}BroadcastDomain" `
                                        -TableArray $PortTextItems `
                                        -ImagesObj $Images `
                                        -IconDebug $IconDebug `
                                        -TableBorder 1 `
                                        -Label "$($BDomain.BroadcastDomain) | MTU: $($BDomain.Mtu)" `
                                        -LabelPos 'top' `
                                        -TableStyle 'rounded,dashed' `
                                        -TableBorderColor '#70AD47' `
                                        -FontName 'Segoe Ui Bold' `
                                        -NodeObject `
                                        -ColumnSize 3 `
                                        -FontSize 14

                                    Add-DiaNodeEdge -From 'DataNetwork' -To "${BDomainSafeName}BroadcastDomain" `
                                        -EdgeColor '#70AD47' `
                                        -EdgeStyle 'dashed' `
                                        -Arrowhead 'none' `
                                        -Arrowtail 'none' `
                                        -EdgeLength 2 `
                                        -EdgeThickness 3
                                }
                            }
                        } catch {
                            Write-PScriboMessage -IsWarning $_.Exception.Message
                        }
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }
            }

        } catch {
            Write-PScriboMessage -IsWarning $_.Exception.Message
        }
    }

    end {}

}