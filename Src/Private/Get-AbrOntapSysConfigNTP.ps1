function Get-AbrOntapSysConfigNTP {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP System NTP information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.6.12
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
        Write-PScriboMessage 'Collecting ONTAP System NTP information.'
    }

    process {
        try {
            $Data = Get-NcNtpServer -Controller $Array
            $OutObj = @()
            if ($Data) {
                foreach ($Item in $Data) {
                    try {
                        $inObj = [ordered] @{
                            'Server Name' = $Item.ServerName
                            'NTP Version' = $TextInfo.ToTitleCase($Item.Version)
                            'Preferred' = ConvertTo-TextYN $Item.IsPreferred
                            'Authentication Enabled' = ConvertTo-TextYN $Item.IsAuthenticationEnabled
                        }
                        $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }

                if ($Healthcheck.System.NTP) {
                    $OutObj.Count -eq 1 | Set-Style -Style Warning
                }

                $TableParams = @{
                    Name = "Network Time Protocol - $($ClusterInfo.ClusterName)"
                    List = $false
                    ColumnWidths = 40, 20, 20, 20
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $OutObj | Table @TableParams
                if ($Healthcheck.System.NTP -and ($OutObj.Count -eq 1)) {
                    Paragraph 'Health Check:' -Bold -Underline
                    BlankLine
                    Paragraph {
                        Text 'Best Practice:' -Bold
                        Text 'It is recommended to configure multiple NTP servers for redundancy and reliability.'
                    }
                    BlankLine
                }
            } else {
                $inObj = [ordered] @{
                    'Server Name' = 'No NTP Servers Configured'
                    'NTP Version' = 'N/A'
                    'Preferred' = 'N/A'
                    'Authentication Enabled' = 'N/A'
                }
                $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                if ($Healthcheck.System.NTP) {
                    $OutObj | Set-Style -Style Warning
                }

                $TableParams = @{
                    Name = "Network Time Protocol - $($ClusterInfo.ClusterName)"
                    List = $false
                    ColumnWidths = 40, 20, 20, 20
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $OutObj | Table @TableParams

                Paragraph 'Health Check:' -Bold -Underline
                BlankLine
                Paragraph {
                    Text 'Best Practice:' -Bold
                    Text 'Configure at least one NTP server to ensure accurate time synchronization across the cluster.'
                }
                BlankLine

            }
        } catch {
            Write-PScriboMessage -IsWarning $_.Exception.Message
        }
    }

    end {}

}