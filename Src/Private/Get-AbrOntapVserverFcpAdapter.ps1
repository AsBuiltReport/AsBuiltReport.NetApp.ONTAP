function Get-AbrOntapVserverFcpAdapter {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP Vserver FCP adapter information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.5.0
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
        Write-PscriboMessage "Collecting ONTAP Vserver FCP adapter information."
    }

    process {
        $VserverData = Get-NcFcpAdapter -Controller $Array | Where-Object {$_.PhysicalProtocol -ne 'ethernet' }
        $VserverObj = @()
        if ($VserverData) {
            foreach ($Item in $VserverData) {
                $inObj = [ordered] @{
                    'Node Name' = $Item.Node
                    'Adapter' = $Item.Adapter
                    'Protocol' = $Item.PhysicalProtocol
                    'Speed' = $Item.Speed
                    'Status' = Switch ($Item.State) {
                        'online' { 'Up' }
                        'offline' { 'Down' }
                        default {$Item.State}
                    }
                }
                $VserverObj += [pscustomobject]$inobj
            }
            if ($Healthcheck.Vserver.FCP) {
                $VserverObj | Where-Object { $_.'Status' -like 'Down' } | Set-Style -Style Warning -Property 'Status'
            }

            $TableParams = @{
                Name = "FCP Physical Adapter Information - $($ClusterInfo.ClusterName)"
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