function Get-AbrOntapSysConfigDNS {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP System DNS Configuration information from the Cluster Management Network
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
        Write-PScriboMessage "Collecting ONTAP System DNS Configuration information."
    }

    process {
        try {
            $Data = Get-NcNetDns -Controller $Array | Where-Object { $_.Vserver -notin $Options.Exclude.Vserver }
            $OutObj = @()
            if ($Data) {
                foreach ($Item in $Data) {
                    try {
                        $inObj = [ordered] @{
                            'Vserver' = $Item.Vserver
                            'Dns State' = $TextInfo.ToTitleCase($Item.DnsState)
                            'Domains' = $Item.Domains
                            'Name Servers' = $Item.NameServers
                            'Timeout/s' = $Item.Timeout
                        }
                        $OutObj += [pscustomobject]$inobj
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }
                if ($Healthcheck.System.DNS) {
                    $OutObj | Where-Object { $_.'Dns State' -notlike 'Enabled' } | Set-Style -Style Warning -Property 'Dns State'
                    $OutObj | Where-Object { $_.'Timeout/s' -gt 10 } | Set-Style -Style Warning -Property 'Timeout/s'
                }

                $TableParams = @{
                    Name = "DNS Configuration - $($ClusterInfo.ClusterName)"
                    List = $false
                    ColumnWidths = 30, 15, 20, 20, 15
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