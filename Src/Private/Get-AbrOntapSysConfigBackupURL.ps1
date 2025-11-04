function Get-AbrOntapSysConfigBackupURL {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP System Configuration Backup Setting nformation from the Cluster Management Network
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
        Write-PScriboMessage "Collecting ONTAP System Configuration Backup Setting information."
    }

    process {
        try {
            $Data = Get-NcConfigBackupUrl -Controller $Array
            $OutObj = @()
            if ($Data) {
                foreach ($Item in $Data) {
                    try {
                        $inObj = [ordered] @{
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
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }

                if ($Healthcheck.System.Backup) {
                    $OutObj | Where-Object { $_.'Url' -eq 'Not Configured' } | Set-Style -Style Warning -Property 'Url'
                    $OutObj | Where-Object { $_.'Username' -eq 'Not Configured' } | Set-Style -Style Warning -Property 'Username'
                }

                $TableParams = @{
                    Name = "Configuration Backup Setting - $($ClusterInfo.ClusterName)"
                    List = $false
                    ColumnWidths = 60, 40
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