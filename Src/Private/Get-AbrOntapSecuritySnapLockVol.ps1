function Get-AbrOntapSecuritySnapLockVol {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP Security Volume Snaplock Type information from the Cluster Management Network
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
        Write-PscriboMessage "Collecting ONTAP Security Volume Snaplock Type information."
    }

    process {
        $Data =  Get-NcVol | Where-Object {$_.JunctionPath -ne '/' -and $_.Name -ne 'vol0'}
        $OutObj = @()
        if ($Data) {
            foreach ($Item in $Data) {
                $SnapLockType = Get-Ncvol $Item.Name | Select-Object -ExpandProperty VolumeSnaplockAttributes
                $inObj = [ordered] @{
                    'Volume' = $Item.Name
                    'Aggregate' = $Item.Aggregate
                    'Snaplock Type' = $TextInfo.ToTitleCase($SnapLockType.SnaplockType)
                }
                $OutObj += [pscustomobject]$inobj
            }

            $TableParams = @{
                Name = "Volume Snaplock Type Information - $($ClusterInfo.ClusterName)"
                List = $false
                ColumnWidths = 45, 35, 20
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $OutObj | Table @TableParams
        }
    }

    end {}

}