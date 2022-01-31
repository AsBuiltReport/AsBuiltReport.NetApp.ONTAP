function Get-AbrOntapNetworkIpSpace {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP Network IpSpace information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.6.3
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
        Write-PscriboMessage "Collecting ONTAP IPSpace information."
    }

    process {
        try {
            $IPSpace = Get-NcNetIpspace -Controller $Array
            $IPSpaceObj = @()
            if ($IPsPace) {
                foreach ($Item in $IPSpace) {
                    try {
                        $inObj = [ordered] @{
                            'Name' = $Item.Ipspace
                            'SVM' = $Item.Vservers -join '; '
                            'Ports' = $Item.Ports -join '; '
                            'Broadcast Domains' = $Item.BroadcastDomains -join '; '
                        }
                        $IPSpaceObj = [pscustomobject]$inobj

                        if ($Healthcheck.Network.Port) {
                            $IPSpaceObj | Where-Object { $_.'Port' -match "Down" } | Set-Style -Style Warning -Property 'Port'
                            $IPSpaceObj | Where-Object { $_.'Port Participation' -ne "full" } | Set-Style -Style Warning -Property 'Port Participation'
                        }

                        $TableParams = @{
                            Name = "Network IPSpace - $($Item.Ipspace)"
                            List = $true
                            ColumnWidths = 25, 75
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $IPSpaceObj | Table @TableParams
                    }
                    catch {
                        Write-PscriboMessage -IsWarning $_.Exception.Message
                    }
                }
            }
        }
        catch {
            Write-PscriboMessage -IsWarning $_.Exception.Message
        }
    }

    end {}

}