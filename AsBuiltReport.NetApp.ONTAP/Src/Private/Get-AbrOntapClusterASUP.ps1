function Get-AbrOntapClusterASUP {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP cluster autoSupport status from the Cluster Management Network
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
        Write-PScriboMessage 'Collecting ONTAP AutoSupport information.'
    }

    process {
        try {
            $AutoSupport = Get-NcAutoSupportConfig -Controller $Array -ErrorAction Continue
            if ($AutoSupport) {
                $Outobj = @()
                foreach ($NodesAUTO in $AutoSupport) {
                    try {
                        $Inobj = [ordered] @{
                            'Node Name' = $NodesAUTO.NodeName
                            'Protocol' = $NodesAUTO.Transport
                            'Enabled' = $NodesAUTO.IsEnabled
                            'Last Time Stamp' = $NodesAUTO.LastTimestampDT
                            'Last Subject' = $NodesAUTO.LastSubject
                            'Ondemand Server URL' = $NodesAUTO.OndemandServerUrl
                            'Validate Digital Certificate' = $NodesAUTO.ValidateDigitalCertificate
                            'Ondemand Remote Diagnostic Enabled' = $NodesAUTO.IsOndemandRemoteDiagEnabled
                            'Performance Data Enabled' = $NodesAUTO.IsPerfDataEnabled
                            'Private Data Removed' = $NodesAUTO.IsPrivateDataRemoved
                            'Support Enabled' = $NodesAUTO.IsSupportEnabled
                        }
                        $Outobj += [pscustomobject](ConvertTo-HashToYN $inObj)

                        if ($Healthcheck.Cluster.AutoSupport) {
                            $Outobj | Where-Object { $_.'Enabled' -like 'No' } | Set-Style -Style Warning -Property 'Enabled'
                        }
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }
                if ($InfoLevel.Storage -ge 2) {
                    foreach ($NodesAUTO in $Outobj) {
                        Section -Style NOTOCHeading4 -ExcludeFromTOC "$($NodesAUTO.'Node Name')" {
                            $TableParams = @{
                                Name = "Cluster AutoSupport Status - $($NodesAUTO.'Node Name')"
                                List = $true
                                ColumnWidths = 40, 60
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $NodesAUTO | Table @TableParams
                            if ($Healthcheck.Cluster.AutoSupport -and ($NodesAUTO | Where-Object { $_.'Enabled' -like 'No' })) {
                                Paragraph 'Health Check:' -Bold -Underline
                                BlankLine
                                Paragraph {
                                    Text 'Best Practice:' -Bold
                                    Text 'AutoSupport is disabled on one or more nodes. It is recommended to enable AutoSupport to ensure proactive monitoring and issue resolution.'
                                }
                                BlankLine
                            }
                        }
                    }
                } else {
                    $TableParams = @{
                        Name = "Cluster AutoSupport Status - $($ClusterInfo.ClusterName)"
                        List = $false
                        Columns = 'Node Name', 'Protocol', 'Enabled'
                        ColumnWidths = 40, 30, 30
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $Outobj | Table @TableParams
                    if ($Healthcheck.Cluster.AutoSupport -and ($Outobj | Where-Object { $_.'Enabled' -like 'No' })) {
                        Paragraph 'Health Check:' -Bold -Underline
                        BlankLine
                        Paragraph {
                            Text 'Best Practice:' -Bold
                            Text 'AutoSupport is disabled on one or more nodes. It is recommended to enable AutoSupport to ensure proactive monitoring and issue resolution.'
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