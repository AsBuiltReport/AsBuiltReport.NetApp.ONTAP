function Get-AbrOntapClusterDiagram {
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
        Write-PScriboMessage "Generating Cluster Diagram for NetApp ONTAP."
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

            # $NodeSum = @(
            #     [pscustomobject]@{
            #         Node = "PHARMAX-HQ-01"
            #         NodeModel = "A400"
            #         NodeSystemId = "1234567890"
            #         NodeSerialNumber = "SN1234567890"
            #     },
            #     [pscustomobject]@{
            #         Node = "PHARMAX-HQ-02"
            #         NodeModel = "A400"
            #         NodeSystemId = "0987654321"
            #         NodeSerialNumber = "SN0987654321"
            #     },
            #     [pscustomobject]@{
            #         Node = "PHARMAX-HQ-03"
            #         NodeModel = "FAS2720"
            #         NodeSystemId = "0987654322"
            #         NodeSerialNumber = "SN0987654322"
            #     },
            #     [pscustomobject]@{
            #         Node = "PHARMAX-HQ-04"
            #         NodeModel = "FAS2720"
            #         NodeSystemId = "0987654323"
            #         NodeSerialNumber = "SN0987654323"
            #     }
            # )
            # $ClusterHaObj = @(
            #     [pscustomobject]@{
            #         Name = "PHARMAX-HQ-01"
            #         Partner = "PHARMAX-HQ-02"
            #         State = "connected"
            #     },
            #     [pscustomobject]@{
            #         Name = "PHARMAX-HQ-02"
            #         Partner = "PHARMAX-HQ-01"
            #         State = "connected"
            #     },
            #     [pscustomobject]@{
            #         Name = "PHARMAX-HQ-03"
            #         Partner = "PHARMAX-HQ-04"
            #         State = "connected"
            #     },
            #     [pscustomobject]@{
            #         Name = "PHARMAX-HQ-04"
            #         Partner = "PHARMAX-HQ-03"
            #         State = "connected"
            #     }
            # )

            SubGraph Cluster -Attributes @{Label = $ClusterInfo.ClusterName; fontsize = 22; penwidth = 1.5; labelloc = 't'; style = "dashed,rounded"; color = "gray" } {
                SubGraph ClusterInfo -Attributes @{Label = "Management: $($ClusterInfo.NcController)"; fontsize = 12; penwidth = 1.5; labelloc = 'b'; labeljust = 'r'; style = "dashed,rounded"; color = "transparent" } {
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
                            # $ClusterHa = $ClusterHaObj | Where-Object { $_.Name -eq $Node.Node }
                            $ClusterHa = try { Get-NcClusterHa -Node $Node.Node -Controller $Array } catch { Write-PScriboMessage -IsWarning $_.Exception.Message }

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
                                    "Model" = $Node.NodeModel
                                    "Mgmt" = switch ([string]::IsNullOrEmpty($NodeMgmtAddress)) {
                                        $true { "Unknown" }
                                        $false { $NodeMgmtAddress }
                                        default { "Unknown" }
                                    }
                                }
                            }
                        }

                        if ($HAObject.Name -and $HAObject.Partner) {
                            foreach ($HA in $HAObject) {
                                $HAClusterName = Remove-SpecialChar -String "HA$($HA.Name)$($HA.Partner)" -SpecialChars '\-_'
                                SubGraph $HAClusterName -Attributes @{Label = "HA Pair"; fontsize = 14; penwidth = 1.5; labelloc = 't'; style = "dashed,rounded"; color = "gray"; labeljust = 'c' } {

                                    $HAName = Remove-SpecialChar -String $HA.Name -SpecialChars '\-_'
                                    $HAPartner = Remove-SpecialChar -String $HA.Partner -SpecialChars '\-_'

                                    Node $HAName @{Label = Add-DiaNodeIcon -Name $HA.Name -AditionalInfo ($NodeAdditionalInfo | Where-Object { $_.NodeName -eq $HA.Name }).AdditionalInfo -ImagesObj $Images -IconType "Ontap_Node" -Align "Center" -IconDebug $IconDebug -FontSize 18; shape = 'plain'; fillColor = 'transparent'; fontsize = 14 }

                                    Node $HAPartner @{Label = Add-DiaNodeIcon -Name $HA.Partner -AditionalInfo ($NodeAdditionalInfo | Where-Object { $_.NodeName -eq $HA.Partner }).AdditionalInfo -ImagesObj $Images -IconType "Ontap_Node" -Align "Center" -IconDebug $IconDebug -FontSize 18; shape = 'plain'; fillColor = 'transparent'; fontsize = 14 }

                                    Rank $HAName, $HAPartner

                                    Edge -From $HAName -To $HAPartner -Attributes @{minlen = 2; label = "HA: $($HA.HAState)"; color = $Edgecolor; fontcolor = $Fontcolor; fontsize = 16; style = 'solid'; penwidth = 2; arrowhead = 'box'; arrowtail = 'box' }
                                }
                            }
                        } else {
                            foreach ($HA in $HAObject) {
                                $HAClusterName = Remove-SpecialChar -String "HA$($HA.Name)" -SpecialChars '\-_'
                                SubGraph $HAClusterName -Attributes @{Label = "Single Node Cluster"; fontsize = 12; penwidth = 1.5; labelloc = 't'; style = "dashed,rounded"; color = "gray"; labeljust = 'c' } {
                                    $HAName = Remove-SpecialChar -String $HA.Name -SpecialChars '\-_'
                                    Node $HAName @{Label = Add-DiaNodeIcon -Name $HA.Name -AditionalInfo ($NodeAdditionalInfo | Where-Object { $_.NodeName -eq $HA.Name }).AdditionalInfo -ImagesObj $Images -IconType "Ontap_Node" -Align "Center" -IconDebug $IconDebug -FontSize 18; shape = 'plain'; fillColor = 'transparent'; fontsize = 14 }
                                }
                            }
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