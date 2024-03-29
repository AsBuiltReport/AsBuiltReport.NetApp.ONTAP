function Get-AbrOntapSysConfigNTP {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP System NTP information from the Cluster Management Network
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
        Write-PScriboMessage "Collecting ONTAP System NTP information."
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
                        $OutObj += [pscustomobject]$inobj
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }

                $TableParams = @{
                    Name = "System Network Time Protocol - $($ClusterInfo.ClusterName)"
                    List = $false
                    ColumnWidths = 40, 20, 20, 20
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