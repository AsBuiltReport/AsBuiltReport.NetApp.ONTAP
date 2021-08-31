function Get-AbrOntapSysConfigBackupURL {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP System Configuration Backup Setting nformation from the Cluster Management Network
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
        Write-PscriboMessage "Collecting ONTAP System Configuration Backup Setting information."
    }

    process {
        $Data =  Get-NcConfigBackupUrl
        $OutObj = @()
        if ($Data) {
            foreach ($Item in $Data) {
                $inObj = [ordered] @{
                    'Cluster IP' = $Item.NcController
                    'Url' = Switch ($Item.Url) {
                        $Null { 'Not Configured' }
                    }
                    'Username' = Switch ($Item.Username) {
                        $Null { 'Not Configured' }
                    }
                }
                $OutObj += [pscustomobject]$inobj
            }

            if ($Healthcheck.System.Backup) {
                $OutObj | Where-Object { $_.'Url' -eq 'Not Configured'} | Set-Style -Style Warning -Property 'Url'
                $OutObj | Where-Object { $_.'Username' -eq 'Not Configured'} | Set-Style -Style Warning -Property 'Username'
            }

            $TableParams = @{
                Name = "System Configuration Backup Setting Information - $($ClusterInfo.ClusterName)"
                List = $false
                ColumnWidths = 20, 60, 20
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $OutObj | Table @TableParams
        }
    }

    end {}

}