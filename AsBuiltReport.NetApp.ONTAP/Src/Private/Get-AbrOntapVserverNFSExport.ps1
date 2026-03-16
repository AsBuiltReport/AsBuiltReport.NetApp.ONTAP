function Get-AbrOntapVserverNFSExport {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP Vserver NFS Export information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.6.12
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
        Write-PScriboMessage 'Collecting ONTAP Vserver NFS Export information.'
    }

    process {
        try {
            $VserverObj = @()
            $NFSVserver = Get-NcNfsExport -VS $Vserver -Controller $Array
            if ($NFSVserver ) {
                foreach ($Item in $NFSVserver) {
                    try {
                        $inObj = [ordered] @{
                            'Path Name' = $Item.Pathname
                            'Export Policy' = (((Get-NcVol -VS $Vserver -Controller $Array | Where-Object { $_.JunctionPath -eq $Item.Pathname }).VolumeExportAttributes).Policy) ?? 'None'
                        }
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                    $VserverObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                }
            }

            $TableParams = @{
                Name = "NFS Service Volume Export - $($Vserver)"
                List = $false
                ColumnWidths = 50, 50
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            if ($VserverObj) {
                $VserverObj | Table @TableParams
            }
        } catch {
            Write-PScriboMessage -IsWarning $_.Exception.Message
        }
    }
    end {}

}