function Get-AbrOntapSysConfigBackup {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP System Configuration Backup nformation from the Cluster Management Network
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
        Write-PscriboMessage "Collecting ONTAP System Configuration Backups information."
    }

    process {
        $Data =  Get-NcConfigBackup
        $OutObj = @()
        if ($Data) {
            foreach ($Item in $Data) {
                $inObj = [ordered] @{
                    'Node' = $Item.Node
                    'Backup Name' = $Item.BackupName
                    'Created' = $Item.Created
                    'Size' = $Item.BackupSize | ConvertTo-FormattedNumber -Type Datasize -ErrorAction SilentlyContinue
                    'Schedule' = $Item.Schedule
                    'Is Auto' = Switch ($Item.IsAuto) {
                        'True' { 'Yes' }
                        'False' { 'No' }
                    }
                }
                $OutObj += [pscustomobject]$inobj
            }

            $TableParams = @{
                Name = "System Configuration Backups Information - $($ClusterInfo.ClusterName)"
                List = $false
                ColumnWidths = 22, 34, 12, 10, 12, 10
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $OutObj | Table @TableParams
        }
    }

    end {}

}