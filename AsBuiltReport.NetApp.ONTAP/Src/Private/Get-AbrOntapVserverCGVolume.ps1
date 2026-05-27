function Get-AbrOntapVserverCGVolume {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP Vserver Consistency Groups Volume information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.6.14
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
        $CGObj
    )

    begin {
        Write-PScriboMessage 'Collecting ONTAP Vserver Consistency Groups volume information.'
    }

    process {
        try {
            $VolumeData = $CGObj.volumes
            $CGVolumeObj = @()
            if ($VolumeData) {
                foreach ($Item in $VolumeData) {
                    try {
                        $inObj = [ordered] @{
                            'Name' = $Item.Name
                            'Capacity' = ($Item.space.size | ConvertTo-FormattedNumber -ErrorAction SilentlyContinue -NumberFormatString 0.0 -Type Datasize) ?? '--'
                            'Used' = ($Item.space.used | ConvertTo-FormattedNumber -ErrorAction SilentlyContinue -NumberFormatString 0.0 -Type Datasize) ?? '--'
                        }
                        $CGVolumeObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }

                $TableParams = @{
                    Name = "Consistency Group Volume - $($CGObj.Name)"
                    List = $false
                    ColumnWidths = 33, 33, 34
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $CGVolumeObj | Sort-Object -Property Name | Table @TableParams
            }
        } catch {
            Write-PScriboMessage -IsWarning $_.Exception.Message
        }
    }

    end {}

}