function Get-AbrOntapVserverCIFSShareProp {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP Vserver CIFS Share Properties information from the Cluster Management Network
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
        Write-PscriboMessage "Collecting ONTAP CIFS Share Properties information."
    }

    process {
        $VserverData = Get-NcCifsShare
        $VserverObj = @()
        if ($VserverData) {
            foreach ($Item in $VserverData) {
                $inObj = [ordered] @{
                    'Vserver Name' = $Item.CifsServer
                    'Share Name' = $Item.ShareName
                    'Share ACL' = $Item.Acl
                    'Share Properties' = ($Item).ShareProperties | Join-String -Separator ', '
                }
                $VserverObj += [pscustomobject]$inobj
            }

            $TableParams = @{
                Name = "The CIFS Share Properties & Acl Information - $($ClusterInfo.ClusterName)"
                List = $false
                ColumnWidths = 20, 20, 30, 30
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $VserverObj | Table @TableParams
        }
    }

    end {}

}