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
                            'Url' = switch ($Item.Url) {
                                $Null { 'Not Configured' }
                                default { $Item.Url }
                            }
                            'Username' = switch ($Item.Username) {
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
                if ($Healthcheck.System.Backup -and ($OutObj | Where-Object { $_.'Url' -eq 'Not Configured' -or $_.'Username' -eq 'Not Configured' })) {
                    Paragraph "Health Check:" -Bold -Underline
                    BlankLine
                    Paragraph {
                        Text "Best Practice:" -Bold
                        Text "It is recommended to backup the system configuration to a remote location to ensure recovery in case of failures."
                    }
                    BlankLine
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning $_.Exception.Message
        }
    }

    end {}

}