function Get-AbrOntapVserverNFSExport {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP Vserver NFS Export information from the Cluster Management Network
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
        Write-PscriboMessage "Collecting ONTAP Vserver NFS Export information."
    }

    process {
        $VserverData = Get-NcVserver | Where-Object { $_.VserverType -eq 'data' -and $_.AllowedProtocols -eq 'nfs' -and $_.State -eq 'running' }
        $VserverObj = @()
        if ($VserverData) {
            foreach ($SVM in $VserverData) {
                $NFSVserver = Get-NcNfsExport -VS $SVM.Vserver
                foreach ($Item in $NFSVserver) {
                    $inObj = [ordered] @{
                        'Path Name' = $Item.Pathname
                        'Vserver' = $SVM.Vserver
                    }
                $VserverObj += [pscustomobject]$inobj
            }
        }

            $TableParams = @{
                Name = "Vserver NFS Service Volume Export Summary - $($ClusterInfo.ClusterName)"
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