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
                            'Partner' = $ClusterHa.Partner ?? '--'
                            'TakeOver Possible' = $ClusterHa.TakeoverPossible
                            'TakeOver State' = $ClusterHa.TakeoverState ?? '--'
                            'HA Mode' = $ClusterHa.CurrentMode
                            'HA State' = $ClusterHa.State
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
                }

                $TableParams = @{
                    Name = "Cluster HA Status - $($ClusterInfo.ClusterName)"
                    List = $false
                    ColumnWidths = 20, 20, 11, 19, 10, 20
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $OutObj | Table @TableParams
                if ($Healthcheck.Cluster.HA -and (($OutObj | Where-Object { $_.'TakeOver State' -like 'in_takeover' } ) -or ($OutObj | Where-Object { $_.'HA Mode' -ne 'non_ha' -and $_.'HA State' -notlike 'connected' }) -or ($OutObj | Where-Object { $_.'TakeOver Possible' -eq 'No' -and $_.'HA Mode' -ne 'non_ha' }))) {
                    Paragraph 'Health Check:' -Bold -Underline
                    BlankLine
                    if ($OutObj | Where-Object { $_.'TakeOver State' -like 'in_takeover' }) {
                        Paragraph {
                            Text 'Best Practice:' -Bold
                            Text 'One or more nodes are currently in takeover state. It is recommended to investigate the cause of the takeover and ensure that the affected node is restored to normal operation as soon as possible.'
                        }
                        BlankLine
                    }
                    if ($OutObj | Where-Object { $_.'TakeOver Possible' -eq 'No' }) {
                        Paragraph {
                            Text 'Best Practice:' -Bold
                            Text 'One or more nodes have takeover capability disabled. It is recommended to enable storage failover capability to ensure high availability in case of node failures.'
                        }
                        BlankLine
                    }
                    if ($OutObj | Where-Object { $_.'HA Mode' -ne 'non_ha' -and $_.'HA State' -notlike 'connected' }) {
                        Paragraph {
                            Text 'Best Practice:' -Bold
                            Text 'One or more nodes are operating in HA mode and are not connected. It is recommended to verify the HA configuration and connectivity to ensure high availability is properly set up.'
                        }
                        BlankLine
                    }
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning $_.Exception.Message
        }
    }

    end {}

}