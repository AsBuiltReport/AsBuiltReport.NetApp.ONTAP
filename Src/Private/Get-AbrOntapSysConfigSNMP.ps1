function Get-AbrOntapSysConfigSNMP {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP System SNMP Configuration information from the Cluster Management Network
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
        Write-PScriboMessage "Collecting ONTAP System SNMP Configuration information."
    }

    process {
        try {
            $Data = Get-NcSnmp -Controller $Array
            $OutObj = @()
            if ($Data) {
                foreach ($Item in $Data) {
                    try {
                        $inObj = [ordered] @{
                            'Contact' = $Item.Contact
                            'Location' = $Item.Location
                            'Communities' = $Item.Communities
                            'Traphosts' = $Item.Traphosts
                            'Status' = Switch ($Item.IsTrapEnabled) {
                                'True' { 'Enabled' }
                                'False' { 'Disabled' }
                                default { $Item.IsTrapEnabled }
                            }
                        }
                        $OutObj += [pscustomobject]$inobj
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }

                $TableParams = @{
                    Name = "System SNMP Configuration - $($ClusterInfo.ClusterName)"
                    List = $true
                    ColumnWidths = 40, 60
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $OutObj | Table @TableParams
            }
        } catch {
            Write-PScriboMessage -IsWarning $_.Exception.Message
        }
    }

    end {}

}