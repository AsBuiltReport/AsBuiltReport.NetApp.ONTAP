function Get-AbrOntapNetworkBdomain {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP Network Broadcast Domain information from the Cluster Management Network
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
        Write-PScriboMessage "Collecting ONTAP Broadcast information."
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

                $TableParams = @{
                    Name = "Network Broadcast Domain - $($ClusterInfo.ClusterName)"
                    List = $false
                    ColumnWidths = 20, 20, 20, 10, 30
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $BDomainObj | Table @TableParams
            }
        } catch {
            Write-PScriboMessage -IsWarning $_.Exception.Message
        }
    }

    end {}

}