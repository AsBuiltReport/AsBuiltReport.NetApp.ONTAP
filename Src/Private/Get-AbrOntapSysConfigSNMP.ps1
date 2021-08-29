function Get-AbrOntapSysConfigSNMP {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP System SNMP Configuration information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.1.0
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
        Write-PscriboMessage "Collecting ONTAP System SNMP Configuration information."
    }

    process {
        $Data =  Get-NcSnmp
        $OutObj = @()
        if ($Data) {
            foreach ($Item in $Data) {
                $inObj = [ordered] @{
                    'Cluster IP' = $Item.NcController
                    'Contact' = $Item.Contact
                    'Location' = $Item.Location
                    'Communities' = $Item.Communities
                    'Traphosts' = $Item.Traphosts
                    'Status' = Switch ($Item.IsTrapEnabled) {
                        'True' { 'Enabled' }
                        'False' { 'Disabled' }
                    }
                }
                $OutObj += [pscustomobject]$inobj
            }

            $TableParams = @{
                Name = "System SNMP Configuration Information - $($ClusterInfo.ClusterName)"
                List = $false
                ColumnWidths = 18, 20, 15, 20, 15, 12
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $OutObj | Table @TableParams
        }
    }

    end {}

}