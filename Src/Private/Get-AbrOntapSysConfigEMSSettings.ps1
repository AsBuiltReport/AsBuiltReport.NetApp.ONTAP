function Get-AbrOntapSysConfigEMSSetting {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP System EMS Settings information from the Cluster Management Network
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
        Write-PScriboMessage "Collecting ONTAP System EMS Settings information."
    }

    process {
        try {
            $Data = Get-NcEmsDestination -Controller $Array
            $OutObj = @()
            if ($Data) {
                foreach ($Item in $Data) {
                    try {
                        $inObj = [ordered] @{
                            'Name' = $Item.Name
                            'Email Destinations' = switch ($Item.Mail) {
                                $Null { '-' }
                                default { $Item.Mail }
                            }
                            'Snmp Traphost' = switch ($Item.Snmp) {
                                $Null { '-' }
                                default { $Item.Snmp }
                            }
                            'Snmp Community' = switch ($Item.SnmpCommunity) {
                                $Null { '-' }
                                default { $Item.SnmpCommunity }
                            }
                            'Syslog' = switch ($Item.Syslog) {
                                $Null { '-' }
                                default { $Item.Syslog }
                            }
                            'Syslog Facility' = switch ($Item.SyslogFacility) {
                                $Null { '-' }
                                default { $Item.SyslogFacility }
                            }
                        }
                        $OutObj += [pscustomobject]$inobj
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }

                $TableParams = @{
                    Name = "EMS Configuration Setting - $($ClusterInfo.ClusterName)"
                    List = $false
                    ColumnWidths = 17, 30, 15, 13, 15, 10
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $OutObj | Table @TableParams
                if ($Healthcheck.System.EMS -and ($OutObj | Where-Object { $_.'Email Destinations' -eq '-' -and $_.'Snmp Traphost' -eq '-' -and $_.'Syslog' -eq '-' })) {
                    Paragraph "Health Check:" -Bold -Underline
                    BlankLine
                    Paragraph {
                        Text "Best Practice:" -Bold
                        Text "It is recommended to configure at least one EMS destination (Email, SNMP, or Syslog) to ensure proper monitoring and alerting of system events."
                    }
                    BlankLine
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning $_.Exception.Message
        }
        try {
            $Data = Get-NcAudit -Controller $Array
            if ($Data) {
                Section -Style Heading4 "Audit Settings" {
                    Paragraph "The following section provides information about Audit Setting from $($ClusterInfo.ClusterName)."
                    BlankLine
                    $OutObj = @()
                    foreach ($Item in $Data) {
                        try {
                            $inObj = [ordered] @{
                                'Enable HTTP Get request' = ConvertTo-TextYN $Item.HttpGet
                                'Enable ONTAPI Get request' = ConvertTo-TextYN $Item.OntapiGet
                                'Enable CLI Get request' = ConvertTo-TextYN $Item.CliGet
                            }
                            $OutObj += [pscustomobject]$inobj
                        } catch {
                            Write-PScriboMessage -IsWarning $_.Exception.Message
                        }
                    }

                    $TableParams = @{
                        Name = "Audit Settings - $($ClusterInfo.ClusterName)"
                        List = $true
                        ColumnWidths = 40, 60
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $OutObj | Table @TableParams
                    try {
                        $Data = Get-NcClusterLogForward -Controller $Array
                        if ($Data) {
                            Section -Style Heading4 "Audit Log Destinations" {
                                $OutObj = @()
                                foreach ($Item in $Data) {
                                    try {
                                        $inObj = [ordered] @{
                                            'Destination' = $Item.Destination
                                            'Facility' = $Item.Facility
                                            'Port' = $Item.Port
                                            'Protocol' = $Item.Protocol
                                            'Server Verification' = ConvertTo-TextYN $Item.VerifyServerSpecified
                                        }
                                        $OutObj += [pscustomobject]$inobj
                                    } catch {
                                        Write-PScriboMessage -IsWarning $_.Exception.Message
                                    }
                                }

                                $TableParams = @{
                                    Name = "Audit Log Destinations - $($ClusterInfo.ClusterName)"
                                    List = $false
                                    ColumnWidths = 20, 20, 20, 20, 20
                                }
                                if ($Report.ShowTableCaptions) {
                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                }
                                $OutObj | Table @TableParams
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