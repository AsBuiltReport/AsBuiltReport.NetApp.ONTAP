function Get-AbrOntapSysConfigEMSSetting {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP System EMS Settings information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.6.3
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
        Write-PscriboMessage "Collecting ONTAP System EMS Settings information."
    }

    process {
        try {
            $Data =  Get-NcEmsDestination -Controller $Array
            $OutObj = @()
            if ($Data) {
                foreach ($Item in $Data) {
                    try {
                        $inObj = [ordered] @{
                            'Name' = $Item.Name
                            'Email Destinations' = Switch ($Item.Mail) {
                                $Null { '-' }
                                default { $Item.Mail }
                            }
                            'Snmp Traphost' = Switch ($Item.Snmp) {
                                $Null { '-' }
                                default { $Item.Snmp }
                            }
                            'Snmp Community' = Switch ($Item.SnmpCommunity) {
                                $Null { '-' }
                                default { $Item.SnmpCommunity }
                            }
                            'Syslog' = Switch ($Item.Syslog) {
                                $Null { '-' }
                                default { $Item.Syslog }
                            }
                            'Syslog Facility' = Switch ($Item.SyslogFacility) {
                                $Null { '-' }
                                default { $Item.SyslogFacility }
                            }
                        }
                        $OutObj += [pscustomobject]$inobj
                    }
                    catch {
                        Write-PscriboMessage -IsWarning $_.Exception.Message
                    }
                }

                $TableParams = @{
                    Name = "System EMS Configuration Setting - $($ClusterInfo.ClusterName)"
                    List = $false
                    ColumnWidths = 17, 30, 15, 13, 15, 10
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $OutObj | Table @TableParams
            }
        }
        catch {
            Write-PscriboMessage -IsWarning $_.Exception.Message
        }
    }

    end {}

}