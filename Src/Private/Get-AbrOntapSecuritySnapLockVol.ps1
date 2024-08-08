function Get-AbrOntapSecuritySnapLockVol {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP Security Volume Snaplock Type information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.6.7
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
        Write-PScriboMessage "Collecting ONTAP Security Volume Snaplock Type information."
    }

    process {
        try {
            $Data = Get-NcVol -Controller $Array | Where-Object { $_.JunctionPath -ne '/' -and $_.Name -ne 'vol0' }
            $OutObj = @()
            if ($Data) {
                foreach ($Item in $Data) {
                    try {
                        $SnapLockType = Get-NcVol $Item.Name -Controller $Array | Select-Object -ExpandProperty VolumeSnaplockAttributes
                        $inObj = [ordered] @{
                            'Volume' = $Item.Name
                            'Aggregate' = $Item.Aggregate
                            'Snaplock Type' = $TextInfo.ToTitleCase($SnapLockType.SnaplockType)
                        }
                        $OutObj += [pscustomobject]$inobj
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }

                $TableParams = @{
                    Name = "Volume Snaplock Type - $($ClusterInfo.ClusterName)"
                    List = $false
                    ColumnWidths = 45, 35, 20
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