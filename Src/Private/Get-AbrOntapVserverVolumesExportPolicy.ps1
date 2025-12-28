function Get-AbrOntapVserverVolumesExportPolicy {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP vserver per volumes export policy information from the Cluster Management Network
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
        Write-PScriboMessage 'Collecting ONTAP Vserver per volumes export policy information.'
    }

    process {
        try {
            $VolumeData = Get-NcVol -VserverContext $Vserver -Controller $Array | Where-Object { $_.JunctionPath -ne '/' -and $_.Name -ne 'vol0' }
            $VolumeObj = @()
            if ($VolumeData) {
                foreach ($Volume in $VolumeData) {
                    try {
                        $inObj = [ordered] @{
                            'Volume Name' = $Volume.Name
                            'Export Policy' = (((Get-NcVol -VS $Vserver -Controller $Array | Where-Object { $_.Name -eq $Volume.Name }).VolumeExportAttributes).Policy) ?? 'None'
                        }
                        $VolumeObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }

                $TableParams = @{
                    Name = "Per Volume Export Policy - $($Vserver)"
                    List = $false
                    ColumnWidths = 50, 50
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $VolumeObj | Table @TableParams
            }
        } catch {
            Write-PScriboMessage -IsWarning $_.Exception.Message
        }
    }

    end {}

}