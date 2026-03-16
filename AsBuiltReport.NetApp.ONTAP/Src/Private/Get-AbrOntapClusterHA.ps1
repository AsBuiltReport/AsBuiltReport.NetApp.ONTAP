function Get-AbrOntapClusterHA {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP cluster HA information from the Cluster Management Network
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
        Write-PScriboMessage 'Collecting ONTAP cluster high availability information.'
    }

    process {
        try {
            $NodeSum = Get-NcNode -Controller $Array | Where-Object { $null -ne $_.NodeModel }
            if ($NodeSum) {
                $OutObj = @()
                foreach ($Nodes in $NodeSum) {
                    try {
                        $ClusterHa = Get-NcClusterHa -Node $Nodes.Node -Controller $Array
                        $inObj = [ordered] @{
                            'Name' = $Nodes.Node
                            'NVRAM ID' = $Nodes.NodeNvramId
                            'Local Mailbox Disks' = ($ClusterHa.LocalMailboxDisks | ForEach-Object { $_.Name }) -join ', '
                            'Partner' = $ClusterHa.Partner ?? '--'
                            'Partner NVRAM ID' = $ClusterHa.PartnerNvramId
                            'Partner Mailbox Disks' = ($ClusterHa.PartnerMailboxDisks | ForEach-Object { $_.Name }) -join ', '
                            'TakeOver Possible' = $ClusterHa.TakeoverPossible
                            'TakeOver By Partner Possible' = $ClusterHa.TakeoverByPartnerPossible
                            'TakeOver State' = $ClusterHa.TakeoverState ?? '--'
                            'HA Mode' = $ClusterHa.CurrentMode
                            'HA Type' = $ClusterHa.HaType
                            'HA State' = $ClusterHa.State
                            'Interconnect Type' = $ClusterHa.InterconnectType
                            'Interconnect Links' = $ClusterHa.InterconnectLinks
                            'Is Enabled' = $ClusterHa.IsEnabled
                        }
                        $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }

                if ($Healthcheck.Cluster.HA) {
                    $OutObj | Where-Object { $_.'TakeOver State' -like 'in_takeover' } | Set-Style -Style Warning -Property 'TakeOver State'
                    $OutObj | Where-Object { $_.'HA Mode' -ne 'non_ha' -and $_.'HA State' -notlike 'connected' } | Set-Style -Style Warning -Property 'HA State'
                    $OutObj | Where-Object { $_.'TakeOver Possible' -eq 'No' -and $_.'HA Mode' -ne 'non_ha' } | Set-Style -Style Warning -Property 'TakeOver Possible'
                    $OutObj | Where-Object { $_.'TakeOver By Partner Possible' -eq 'No' -and $_.'HA Mode' -ne 'non_ha' } | Set-Style -Style Warning -Property 'TakeOver By Partner Possible'
                    $OutObj | Where-Object { $_.'Is Enabled' -eq 'No' -and $_.'HA Mode' -ne 'non_ha' } | Set-Style -Style Warning -Property 'Is Enabled'

                }

                if ($InfoLevel.Cluster -ge 2) {
                    foreach ($NodeHa in $OutObj) {
                        Section -Style NOTOCHeading4 -ExcludeFromTOC "$($NodeHa.Name)" {
                            $TableParams = @{
                                Name = "Cluster HA Status - $($NodeHa.Name)"
                                List = $true
                                ColumnWidths = 40, 60
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $NodeHa | Table @TableParams
                            if ($Healthcheck.Cluster.HA -and (($NodeHa | Where-Object { $_.'TakeOver State' -like 'in_takeover' } ) -or ($NodeHa | Where-Object { $_.'HA Mode' -ne 'non_ha' -and $_.'HA State' -notlike 'connected' }) -or ($NodeHa | Where-Object { $_.'TakeOver Possible' -eq 'No' -and $_.'HA Mode' -ne 'non_ha' }))) {
                                Paragraph 'Health Check:' -Bold -Underline
                                BlankLine
                                if ($NodeHa | Where-Object { $_.'TakeOver State' -like 'in_takeover' }) {
                                    Paragraph {
                                        Text 'Best Practice:' -Bold
                                        Text 'One or more nodes are currently in takeover state. It is recommended to investigate the cause of the takeover and ensure that the affected node is restored to normal operation as soon as possible.'
                                    }
                                    BlankLine
                                }
                                if ($NodeHa | Where-Object { $_.'TakeOver Possible' -eq 'No' }) {
                                    Paragraph {
                                        Text 'Best Practice:' -Bold
                                        Text 'One or more nodes have takeover capability disabled. It is recommended to enable storage failover capability to ensure high availability in case of node failures.'
                                    }
                                    BlankLine
                                }
                                if ($NodeHa | Where-Object { $_.'HA Mode' -ne 'non_ha' -and $_.'HA State' -notlike 'connected' }) {
                                    Paragraph {
                                        Text 'Best Practice:' -Bold
                                        Text 'One or more nodes are operating in HA mode and are not connected. It is recommended to verify the HA configuration and connectivity to ensure high availability is properly set up.'
                                    }
                                    BlankLine
                                }
                                if ($NodeHa | Where-Object { $_.'Is Enabled' -eq 'No' -and $_.'HA Mode' -ne 'non_ha' }) {
                                    Paragraph {
                                        Text 'Best Practice:' -Bold
                                        Text 'One or more nodes have HA disabled while operating in HA mode. It is recommended to enable HA to ensure redundancy and high availability.'
                                    }
                                    BlankLine
                                }
                            }
                        }
                    }
                } else {
                    $TableParams = @{
                        Name = "Cluster AutoSupport Status - $($ClusterInfo.ClusterName)"
                        List = $false
                        Columns = 'Name', 'Partner', 'TakeOver Possible', 'TakeOver State', 'HA Mode', 'HA State'
                        ColumnWidths = 20, 20, 11, 19, 10, 20
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $Outobj | Table @TableParams
                    if ($Healthcheck.Cluster.HA -and (($Outobj | Where-Object { $_.'TakeOver State' -like 'in_takeover' } ) -or ($Outobj | Where-Object { $_.'HA Mode' -ne 'non_ha' -and $_.'HA State' -notlike 'connected' }) -or ($Outobj | Where-Object { $_.'TakeOver Possible' -eq 'No' -and $_.'HA Mode' -ne 'non_ha' }))) {
                        Paragraph 'Health Check:' -Bold -Underline
                        BlankLine
                        if ($Outobj | Where-Object { $_.'TakeOver State' -like 'in_takeover' }) {
                            Paragraph {
                                Text 'Best Practice:' -Bold
                                Text 'One or more nodes are currently in takeover state. It is recommended to investigate the cause of the takeover and ensure that the affected node is restored to normal operation as soon as possible.'
                            }
                            BlankLine
                        }
                        if ($Outobj | Where-Object { $_.'TakeOver Possible' -eq 'No' }) {
                            Paragraph {
                                Text 'Best Practice:' -Bold
                                Text 'One or more nodes have takeover capability disabled. It is recommended to enable storage failover capability to ensure high availability in case of node failures.'
                            }
                            BlankLine
                        }
                        if ($Outobj | Where-Object { $_.'HA Mode' -ne 'non_ha' -and $_.'HA State' -notlike 'connected' }) {
                            Paragraph {
                                Text 'Best Practice:' -Bold
                                Text 'One or more nodes are operating in HA mode and are not connected. It is recommended to verify the HA configuration and connectivity to ensure high availability is properly set up.'
                            }
                            BlankLine
                        }
                        if ($Outobj | Where-Object { $_.'Is Enabled' -eq 'No' -and $_.'HA Mode' -ne 'non_ha' }) {
                            Paragraph {
                                Text 'Best Practice:' -Bold
                                Text 'One or more nodes have HA disabled while operating in HA mode. It is recommended to enable HA to ensure redundancy and high availability.'
                            }
                            BlankLine
                        }
                    }
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning $_.Exception.Message
        }
    }

    end {}

}