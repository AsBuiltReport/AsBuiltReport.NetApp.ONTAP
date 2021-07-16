function Get-AbrOntapVserverFcp {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP Vserver FCP information from the Cluster Management Network
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
        Write-PscriboMessage "Collecting ONTAP Vserver FCP information."
    }

    process {
        $VserverData = Get-NcFcpService
        $VserverObj = @()
        if ($VserverData) {
            foreach ($Item in $VserverData) {
                $inObj = [ordered] @{
                    'Vserver' = $Item.Vserver
                    'Status' = Switch ($Item.IsAvailable) {
                        'True' { 'Up' }
                        'False' { 'Down' }
                    }
                    'FCP WWNN' = $Item.NodeName
                }
                $VserverObj += [pscustomobject]$inobj
            }
            if ($Healthcheck.Vserver.FCP) {
                $VserverObj | Where-Object { $_.'Status' -like 'Down' } | Set-Style -Style Warning -Property 'Status'
            }

            $TableParams = @{
                Name = "Vserver FCP Service Information - $($ClusterInfo.ClusterName)"
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