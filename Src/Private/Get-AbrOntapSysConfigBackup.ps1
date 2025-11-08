function Get-AbrOntapSysConfigBackup {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP System Configuration Backup nformation from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.6.7
        Author:         Jonathan Colon
        Twitter:        @jcolonfzenpr
        Github:         rebelinux
    .EXAMPLE

    .LINK

    #>
    param (
        [Parameter (
            Position = 0,
            Mandatory)]
        [string]
        $Node
    )

    begin {
        Write-PScriboMessage "Collecting ONTAP System Configuration Backups information."
    }

    process {
        try {
            $Data = Get-NcConfigBackup -Node $Node -Controller $Array
            $OutObj = @()
            if ($Data) {
                foreach ($Item in $Data) {
                    try {
                        $inObj = [ordered] @{
                            'Backup Name' = $Item.BackupName
                            'Created' = $Item.Created
                            'Size' = $Item.BackupSize | ConvertTo-FormattedNumber -Type Datasize -ErrorAction SilentlyContinue
                            'Schedule' = $Item.Schedule
                            'Is Auto' = ConvertTo-TextYN $Item.IsAuto
                        }
                        $OutObj += [pscustomobject]$inobj
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }

                $TableParams = @{
                    Name = "Configuration Backups - $($Node)"
                    List = $false
                    ColumnWidths = 40, 15, 15, 15, 15
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