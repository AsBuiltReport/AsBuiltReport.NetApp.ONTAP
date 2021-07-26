function Get-AbrOntapVserverVolumesQtree {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP vserver volumes qtree information from the Cluster Management Network
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
        Write-PscriboMessage "Collecting ONTAP Vserver volumes qtree information."
    }

    process {
        $Unit = "GB"
        $VserverQtree = Get-NcQtree | Where-Object {$NULL -ne $_.Qtree}
        $VserverObj = @()
        if ($VserverQtree) {
            foreach ($Item in $VserverQtree) {
                $inObj = [ordered] @{
                    'Qtree' = $Item.Qtree
                    'Volume' = $Item.Volume
                    'Status' = $Item.Status
                    'Security Style' = $Item.SecurityStyle
                    'Export Policy' = $Item.ExportPolicy
                    'Vserver' = $Item.Vserver
                }
                $VserverObj += [pscustomobject]$inobj
            }
            if ($Healthcheck.Vserver.Status) {
                $VserverObj | Where-Object { $_.'Status' -notlike 'normal' } | Set-Style -Style Warning -Property 'Status'
            }

            $TableParams = @{
                Name = "Vserver Volume Qtree Information - $($ClusterInfo.ClusterName)"
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