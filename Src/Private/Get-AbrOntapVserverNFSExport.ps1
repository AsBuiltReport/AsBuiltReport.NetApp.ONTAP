function Get-AbrOntapVserverNFSExport {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP Vserver NFS Export information from the Cluster Management Network
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
        Write-PscriboMessage "Collecting ONTAP Vserver NFS Export information."
    }

    process {
        $VserverData = Get-NcVserver -VserverContext $Vserver | Where-Object { $_.VserverType -eq 'data' -and $_.AllowedProtocols -eq 'nfs' -and $_.State -eq 'running' }
        $VserverObj = @()
        if ($VserverData) {
            foreach ($SVM in $VserverData) {
                $NFSVserver = Get-NcNfsExport -VS $SVM.Vserver
                foreach ($Item in $NFSVserver) {
                    $inObj = [ordered] @{
                        'Vserver' = $SVM.Vserver
                        'Path Name' = $Item.Pathname
                    }
                $VserverObj += [pscustomobject]$inobj
            }
        }

            $TableParams = @{
                Name = "Vserver NFS Service Volume Export Summary - $($Vserver)"
                List = $false
                ColumnWidths = 35, 65
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            if ($VserverObj) {
                $VserverObj | Table @TableParams
            }
        }
    }

    end {}

}