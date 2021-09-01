function Get-AbrOntapSysConfigNTP {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP System NTP information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.3.0
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
        Write-PscriboMessage "Collecting ONTAP System NTP information."
    }

    process {
        $Data =  Get-NcNtpServer
        $OutObj = @()
        if ($Data) {
            foreach ($Item in $Data) {
                $inObj = [ordered] @{
                    'Server Name' = $Item.ServerName
                    'NTP Version' = $TextInfo.ToTitleCase($Item.Version)
                    'Preferred' = Switch ($Item.IsPreferred) {
                        'True' { 'Yes' }
                        'False' { 'No' }
                    }
                    'Authentication Enabled' = Switch ($Item.IsAuthenticationEnabled) {
                        'True' { 'Yes' }
                        'False' { 'No' }
                    }
                }
                $OutObj += [pscustomobject]$inobj
            }

            $TableParams = @{
                Name = "System Network Time Protocol Information - $($ClusterInfo.ClusterName)"
                List = $false
                ColumnWidths = 40, 20, 20, 20
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $OutObj | Table @TableParams
        }
    }

    end {}

}