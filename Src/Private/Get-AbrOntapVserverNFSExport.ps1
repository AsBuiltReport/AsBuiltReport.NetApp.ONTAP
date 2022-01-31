function Get-AbrOntapVserverNFSExport {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP Vserver NFS Export information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.6.3
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
        try {
            $VserverData = Get-NcVserver -VserverContext $Vserver -Controller $Array | Where-Object { $_.VserverType -eq 'data' -and $_.AllowedProtocols -eq 'nfs' -and $_.State -eq 'running' }
            $VserverObj = @()
            if ($VserverData) {
                foreach ($SVM in $VserverData) {
                    try {
                        $NFSVserver = Get-NcNfsExport -VS $SVM.Vserver -Controller $Array
                        foreach ($Item in $NFSVserver) {
                            try {
                                $inObj = [ordered] @{
                                    'Vserver' = $SVM.Vserver
                                    'Path Name' = $Item.Pathname
                                }
                            }
                            catch {
                                Write-PscriboMessage -IsWarning $_.Exception.Message
                            }
                        }
                        $VserverObj += [pscustomobject]$inobj
                    }
                    catch {
                        Write-PscriboMessage -IsWarning $_.Exception.Message
                    }
                }

                $TableParams = @{
                    Name = "Vserver NFS Service Volume Export - $($Vserver)"
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
        catch {
            Write-PscriboMessage -IsWarning $_.Exception.Message
        }
    }
    end {}

}