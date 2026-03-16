function Get-AbrOntapVserverVolumesInodeAttr {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP vserver per volumes inode attributes information from the Cluster Management Network
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
        Write-PScriboMessage 'Collecting ONTAP Vserver per volumes inode attributes information.'
    }

    process {
        try {
            $VolumeFilter = Get-NcVol -VserverContext $Vserver -Controller $Array | Where-Object { $_.JunctionPath -ne '/' -and $_.Name -ne 'vol0' }
            $OutObj = @()
            if ($VolumeFilter) {
                foreach ($Item in $VolumeFilter) {
                    try {
                        $InodeAttr = $Item.VolumeInodeAttributes
                        $inObj = [ordered] @{
                            'Volume' = $Item.Name
                            'Files Total' = $InodeAttr.FilesTotal ?? '--'
                            'Files Used' = $InodeAttr.FilesUsed ?? '--'
                            'Files Private Used' = $InodeAttr.FilesPrivateUsed ?? '--'
                            'Inode File Private Capacity' = $InodeAttr.InodefilePrivateCapacity ?? '--'
                            'Inode File Public Capacity' = $InodeAttr.InodefilePublicCapacity ?? '--'
                        }
                        $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }

                $TableParams = @{
                    Name = "Per Volume Inode Attributes - $($Vserver)"
                    List = $false
                    ColumnWidths = 22, 14, 14, 16, 17, 17
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $OutObj | Table @TableParams
            }
        } catch {
            Write-PScriboMessage -IsWarning $_.Exception.Message
        }
    }

    end {}

}
