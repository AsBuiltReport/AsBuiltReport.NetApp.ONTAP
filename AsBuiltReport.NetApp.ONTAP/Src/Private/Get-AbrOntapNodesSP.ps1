function Get-AbrOntapNodesSP {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP system nodes service-processor information from the Cluster Management Network
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
        Write-PScriboMessage 'Collecting ONTAP Node Service-Processor information.'
    }

    process {
        try {
            $ServiceProcessor = Get-NcServiceProcessor -Controller $Array

            # $ServiceProcessor = @(
            #     @{
            #         'Node' = 'cluster-01'
            #         'Type' = 'BMC'
            #         'IpAddress' = '192.168.0.1'
            #         'MacAddress' = '00:02:23:24:43:AA'
            #         'IsIpConfigured' = 'True'
            #         'FirmwareVersion' = '8.1'
            #         'Status' = 'Online'
            #     },
            #     @{
            #         'Node' = 'cluster-02'
            #         'Type' = 'BMC'
            #         'IpAddress' = '192.168.0.2'
            #         'MacAddress' = '00:02:23:24:43:AB'
            #         'IsIpConfigured' = 'True'
            #         'FirmwareVersion' = '8.1'
            #         'Status' = 'Online'
            #     },
            #     @{
            #         'Node' = 'cluster-03'
            #         'Type' = 'BMC'
            #         'IpAddress' = '192.168.0.2'
            #         'MacAddress' = '00:02:23:24:43:AB'
            #         'IsIpConfigured' = 'True'
            #         'FirmwareVersion' = '8.1'
            #         'Status' = 'Unknown'
            #     },
            #     @{
            #         'Node' = 'cluster-04'
            #         'Type' = 'BMC'
            #         'IpAddress' = ''
            #         'MacAddress' = '00:02:23:24:43:AB'
            #         'IsIpConfigured' = 'False'
            #         'FirmwareVersion' = '8.1'
            #         'Status' = 'Offline'
            #     }
            # )
            if ($ServiceProcessor) {
                $SPObj = @()
                foreach ($NodeSPs in $ServiceProcessor) {
                    try {
                        $inObj = [ordered] @{
                            'Name' = $NodeSPs.Node
                            'Type' = $NodeSPs.Type
                            'IP Address' = $NodeSPs.IpAddress
                            'MAC Address' = $NodeSPs.MacAddress
                            'Network Configured' = $NodeSPs.IsIpConfigured
                            'Firmware' = $NodeSPs.FirmwareVersion
                            'Status' = $NodeSPs.Status
                        }
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }

                    $SPObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                }
                if ($Healthcheck.Node.ServiceProcessor) {
                    $SPObj | Where-Object { $_.'Status' -like 'offline' -or $_.'Status' -like 'degraded' } | Set-Style -Style Critical -Property 'Status'
                    $SPObj | Where-Object { $_.'Status' -like 'unknown' -or $_.'Status' -like 'sp-daemon-offline' } | Set-Style -Style Warning -Property 'Status'
                    $SPObj | Where-Object { $_.'Network Configured' -eq 'No' } | Set-Style -Style Critical -Property 'Network Configured'
                }

                $TableParams = @{
                    Name = "Node Service-Processor - $($ClusterInfo.ClusterName)"
                    List = $false
                    ColumnWidths = 16, 11, 16, 20, 13, 12, 12
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $SPObj | Table @TableParams
                if ($Healthcheck.Node.ServiceProcessor -and ($SPObj | Where-Object { $_.'Status' -in @('unknown', 'offline', 'degraded') -or $_.'Network Configured' -eq 'No' })) {
                    Paragraph 'Health Check:' -Bold -Underline
                    BlankLine
                    Paragraph {
                        Text 'Best Practice:' -Bold
                        Text 'Ensure that all service-processors are online, configured and functioning properly to maintain system management capabilities.'
                    }
                    BlankLine
                }
            }

        } catch {
            Write-PScriboMessage -IsWarning $_.Exception.Message
        }
    }

    end {}

}