function Get-AbrOntapVserverNFSSummary {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP Vserver NFS information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.4.0
        Author:         Jonathan Colon
        Twitter:        @jcolonfzenpr
        Github:         rebelinux
    .EXAMPLE

    .LINK

    #>
    param (
        [Parameter (
            Position = 0,
            Mandatory)]
            [string]
            $Vserver
    )

    begin {
        Write-PscriboMessage "Collecting ONTAP Vserver NFS information."
    }

    process {
        $VserverData = Get-NcNfsService -VserverContext $Vserver
        $VserverObj = @()
        if ($VserverData) {
            foreach ($Item in $VserverData) {
                $inObj = [ordered] @{
                    'Nfs v3' = Switch ($Item.IsNfsv3) {
                        'True' { 'Enabled' }
                        'False' { 'Disabled' }
                        default {$Item.IsNfsv3}
                    }
                    'Nfs v4' = Switch ($Item.IsNfsv4) {
                        'True' { 'Enabled' }
                        'False' { 'Disabled' }
                        default {$Item.IsNfsv4}
                    }
                    'Nfs v41' = Switch ($Item.IsNfsv41) {
                        'True' { 'Enabled' }
                        'False' { 'Disabled' }
                        default {$Item.IsNfsv41}
                    }
                    'General Access' = ConvertTo-TextYN $Item.GeneralAccess

                }
                $VserverObj += [pscustomobject]$inobj
            }
            if ($Healthcheck.Vserver.NFS) {
                $VserverObj | Where-Object { $_.'Nfs v3' -like 'Disabled' } | Set-Style -Style Warning -Property 'Nfs v3'
                $VserverObj | Where-Object { $_.'Nfs v4' -like 'Disabled' } | Set-Style -Style Warning -Property 'Nfs v4'
                $VserverObj | Where-Object { $_.'Nfs v41' -like 'Disabled' } | Set-Style -Style Warning -Property 'Nfs v41'
            }

            $TableParams = @{
                Name = "Vserver NFS Service Information - $($ClusterInfo.ClusterName)"
                List = $false
                ColumnWidths = 25, 25, 25, 25
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $VserverObj | Table @TableParams
        }
    }

    end {}

}