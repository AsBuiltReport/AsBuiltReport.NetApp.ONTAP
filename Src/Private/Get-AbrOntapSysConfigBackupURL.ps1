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
                    'Url' = $Item.Url
                    'Username' = $Item.Username
                }
                $OutObj += [pscustomobject]$inobj
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