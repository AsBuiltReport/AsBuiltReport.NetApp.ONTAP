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
        Write-PScriboMessage "Collecting ONTAP Node Service-Processor information."
    }

    process {
        try {
            $ServiceProcessor = Get-NcServiceProcessor -Controller $Array
            if ($ServiceProcessor) {
                foreach ($NodeSPs in $ServiceProcessor) {
                    Section -ExcludeFromTOC -Style NOTOCHeading5 $NodeSPs.Node {

                        $SPObj = @()
                        try {
                            $inObj = [ordered] @{
                                'Name' = $NodeSPs.Node
                                'Type' = $NodeSPs.Type
                                'IP Address' = $NodeSPs.IpAddress
                                'MAC Address' = $NodeSPs.MacAddress
                                'Network Configured' = ConvertTo-TextYN $NodeSPs.IsIpConfigured
                                'Firmware' = $NodeSPs.FirmwareVersion
                                'Status' = $NodeSPs.Status
                            }
                        } catch {
                            Write-PScriboMessage -IsWarning $_.Exception.Message
                        }

                        $SPObj += [pscustomobject]$inobj

                        if ($Healthcheck.Node.ServiceProcessor) {
                            $SPObj | Where-Object { $_.'Status' -like 'offline' -or $_.'Status' -like 'degraded' } | Set-Style -Style Critical -Property 'Status'
                            $SPObj | Where-Object { $_.'Status' -like 'unknown' -or $_.'Status' -like 'sp-daemon-offline' } | Set-Style -Style Warning -Property 'Status'
                            $SPObj | Where-Object { $_.'Network Configured' -eq "No" } | Set-Style -Style Critical -Property 'Network Configured'
                        }

                        $TableParams = @{
                            Name = "Node Service-Processor - $($NodeSPs.Node)"
                            List = $true
                            ColumnWidths = 30, 70
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $SPObj | Table @TableParams
                        if ($Healthcheck.Node.ServiceProcessor -and ($SPObj | Where-Object { $_.'Status' -like 'offline' -or $_.'Status' -like 'degraded' })) {
                            Paragraph "Health Check:" -Bold -Underline
                            BlankLine
                            Paragraph {
                                Text "Best Practice:" -Bold
                                Text "Ensure that all service-processors are online and functioning properly to maintain system management capabilities."
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