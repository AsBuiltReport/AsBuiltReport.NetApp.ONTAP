function Get-AbrOntapSysConfigBackupURL {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP System Configuration Backup Setting nformation from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.6.2
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
        $Data =  Get-NcConfigBackupUrl -Controller $Array
        $OutObj = @()
        if ($Data) {
            foreach ($Item in $Data) {
                $inObj = [ordered] @{
                    'Cluster IP' = $Item.NcController
                    'Url' = Switch ($Item.Url) {
                        $Null { 'Not Configured' }
                        default { $Item.Url }
                    }
                    'Username' = Switch ($Item.Username) {
                        $Null { 'Not Configured' }
                        default { $Item.Username }
                    }
                }
                $OutObj += [pscustomobject]$inobj
            }

            if ($Healthcheck.System.Backup) {
                $OutObj | Where-Object { $_.'Url' -eq 'Not Configured'} | Set-Style -Style Warning -Property 'Url'
                $OutObj | Where-Object { $_.'Username' -eq 'Not Configured'} | Set-Style -Style Warning -Property 'Username'
            }

            $TableParams = @{
                Name = "System Configuration Backup Setting - $($ClusterInfo.ClusterName)"
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