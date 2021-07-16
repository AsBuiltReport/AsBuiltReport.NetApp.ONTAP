function Get-AbrOntapVserverSummary {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP Vserver information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.1.0
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
        Write-PscriboMessage "Collecting ONTAP Vserver information."
    }

    process {
        $VserverData = Get-NcVserver
        $VserverObj = @()
        if ($VserverData) {
            foreach ($Item in $VserverData) {
                $inObj = [ordered] @{
                    'Vserver Name' = $Item.Vserver
                    'Status' = $Item.State
                    'Vserver Type' = $Item.VserverType
                    'Allowed Protocols' = [string]$Item.AllowedProtocols
                    'Disallowed Protocols' = [string]$Item.DisallowedProtocols
                    'IP Space' = $Item.Ipspace
                }
                $VserverObj += [pscustomobject]$inobj
            }
            if ($Healthcheck.Vserver.Status) {
                $VserverObj | Where-Object { $_.'Status' -like 'stopped' } | Set-Style -Style Warning -Property 'Status'
            }

            $TableParams = @{
                Name = "Vserver Summary Information - $($ClusterInfo.ClusterName)"
                List = $false
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $VserverObj | Table @TableParams
        }
    }

    end {}

}