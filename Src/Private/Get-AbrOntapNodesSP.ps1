function Get-AbrOntapNodesSP {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP system nodes service-processor information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.4.0
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
        Write-PscriboMessage "Collecting ONTAP Node Service-Processor information."
    }

    process {
        $ServiceProcessor = Get-NcServiceProcessor
        if ($ServiceProcessor) {
            $NodeServiceProcessor = foreach ($NodeSPs in $ServiceProcessor) {
                [PSCustomObject] @{
                    'Name' = $NodeSPs.Node
                    'Type' = $NodeSPs.Type
                    'IP Address' = $NodeSPs.IpAddress
                    'MAC Address' = $NodeSPs.MacAddress
                    'Network Configured' = $NodeSPs.IsIpConfigured
                    'Firmware' = $NodeSPs.FirmwareVersion
                    'Status' = $NodeSPs.Status
                }
            }
            if ($Healthcheck.Node.ServiceProcessor) {
                $NodeServiceProcessor | Where-Object { $_.'Status' -like 'offline' -or $_.'Status' -like 'degraded' } | Set-Style -Style Critical -Property 'Status'
                $NodeServiceProcessor | Where-Object { $_.'Status' -like 'unknown' -or $_.'Status' -like 'sp-daemon-offline' } | Set-Style -Style Warning -Property 'Status'
                $NodeServiceProcessor | Where-Object { $_.'Network Configured' -like "false" } | Set-Style -Style Critical -Property 'Network Configured'
            }
        }

        $TableParams = @{
            Name = "Node Service-Processor Information - $($ClusterInfo.ClusterName)"
            List = $true
            ColumnWidths = 35, 65
        }
        if ($Report.ShowTableCaptions) {
            $TableParams['Caption'] = "- $($TableParams.Name)"
        }
        $NodeServiceProcessor | Table @TableParams
    }

    end {}

}