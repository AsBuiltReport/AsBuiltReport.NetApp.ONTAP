function Get-AbrOntapSysConfigDNS {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP System DNS Configuration information from the Cluster Management Network
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
        Write-PscriboMessage "Collecting ONTAP System DNS Configuration information."
    }

    process {
        $Data =  Get-NcNetDns -Controller $Array
        $OutObj = @()
        if ($Data) {
            foreach ($Item in $Data) {
                $inObj = [ordered] @{
                    'Vserver' = $Item.Vserver
                    'Dns State' = $TextInfo.ToTitleCase($Item.DnsState)
                    'Domains' = $Item.Domains
                    'Name Servers' = $Item.NameServers
                    'Timeout/s' = $Item.Timeout
                }
                $OutObj += [pscustomobject]$inobj
            }
            if ($Healthcheck.System.DNS) {
                $OutObj | Where-Object { $_.'Dns State' -notlike 'Enabled' } | Set-Style -Style Warning -Property 'Dns State'
                $OutObj | Where-Object { $_.'Timeout/s' -gt 10 } | Set-Style -Style Warning -Property 'Timeout/s'
            }

            $TableParams = @{
                Name = "System DNS Configuration - $($ClusterInfo.ClusterName)"
                List = $false
                ColumnWidths = 30, 15, 20, 20, 15
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $OutObj | Table @TableParams
        }
    }

    end {}

}