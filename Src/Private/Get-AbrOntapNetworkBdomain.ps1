function Get-AbrOntapNetworkBdomain {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP Network Broadcast Domain information from the Cluster Management Network
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
        Write-PScriboMessage 'Collecting ONTAP Broadcast information.'
    }

    process {
        try {
            $BDomain = Get-NcNetPortBroadcastDomain -Controller $Array
            $BDomainObj = @()
            if ($BDomain) {
                foreach ($Item in $BDomain) {
                    $inObj = [ordered] @{
                        'Name' = $Item.BroadcastDomain
                        'IPSpace' = $Item.Ipspace
                        'Failover Groups' = $Item.FailoverGroups
                        'MTU' = $Item.Mtu
                        'Ports' = $Item.Ports
                    }
                    $BDomainObj += [pscustomobject]$inobj
                }

                if ($Healthcheck.Network.Port) {
                    $BDomainObj | Where-Object { $null -eq $_.'Failover Groups' -and $null -eq $_.'Ports' } | Set-Style -Style Warning
                }

                $TableParams = @{
                    Name = "Network Broadcast Domain - $($ClusterInfo.ClusterName)"
                    List = $false
                    ColumnWidths = 20, 20, 20, 10, 30
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $BDomainObj | Table @TableParams
                if ($Healthcheck.Network.Port -and ($BDomainObj | Where-Object { $null -eq $_.'Failover Groups' -and $null -eq $_.'Ports' })) {
                    Paragraph 'Health Check:' -Bold -Underline
                    BlankLine
                    Paragraph {
                        Text 'Best Practice:' -Bold
                        Text ' Broadcast Domains should have associated Failover Groups and Ports assigned to them, review the highlighted Broadcast Domains above and take corrective action as necessary.'
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