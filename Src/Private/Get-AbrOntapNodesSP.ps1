function Get-AbrOntapNodesSP {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP system nodes service-processor information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.6.7
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
        Write-PScriboMessage "Collecting ONTAP Node Service-Processor information."
    }

    process {
        try {
            $ServiceProcessor = Get-NcServiceProcessor -Controller $Array
            if ($ServiceProcessor) {
                $NodeServiceProcessor = foreach ($NodeSPs in $ServiceProcessor) {
                    try {
                        [PSCustomObject] @{
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
                }
                if ($Healthcheck.Node.ServiceProcessor) {
                    $NodeServiceProcessor | Where-Object { $_.'Status' -like 'offline' -or $_.'Status' -like 'degraded' } | Set-Style -Style Critical -Property 'Status'
                    $NodeServiceProcessor | Where-Object { $_.'Status' -like 'unknown' -or $_.'Status' -like 'sp-daemon-offline' } | Set-Style -Style Warning -Property 'Status'
                    $NodeServiceProcessor | Where-Object { $_.'Network Configured' -like "false" } | Set-Style -Style Critical -Property 'Network Configured'
                }
            }

            $TableParams = @{
                Name = "Node Service-Processor - $($ClusterInfo.ClusterName)"
                List = $true
                ColumnWidths = 35, 65
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $NodeServiceProcessor | Table @TableParams
            if ($Healthcheck.Node.ServiceProcessor -and ($NodeServiceProcessor | Where-Object { $_.'Status' -like 'offline' -or $_.'Status' -like 'degraded' })) {
                Paragraph "Health Check:" -Bold -Underline
                BlankLine
                Paragraph {
                    Text "Best Practice:" -Bold
                    Text "Ensure that all service-processors are online and functioning properly to maintain system management capabilities."
                }
                BlankLine
            }
        } catch {
            Write-PScriboMessage -IsWarning $_.Exception.Message
        }
    }

    end {}

}