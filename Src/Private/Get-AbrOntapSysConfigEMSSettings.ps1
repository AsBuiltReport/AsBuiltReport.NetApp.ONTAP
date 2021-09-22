function Get-AbrOntapSysConfigEMSSettings {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP System EMS Settings information from the Cluster Management Network
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
        Write-PscriboMessage "Collecting ONTAP System EMS Settings information."
    }

    process {
        $Data =  Get-NcEmsDestination
        $OutObj = @()
        if ($Data) {
            foreach ($Item in $Data) {
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

            $TableParams = @{
                Name = "System EMS Configuration Setting Information - $($ClusterInfo.ClusterName)"
                List = $false
                ColumnWidths = 17, 30, 15, 13, 15, 10
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $OutObj | Table @TableParams
        }
    }

    end {}

}