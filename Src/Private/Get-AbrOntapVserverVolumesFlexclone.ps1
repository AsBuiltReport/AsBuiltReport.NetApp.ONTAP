function Get-AbrOntapVserverVolumesFlexclone {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP vserver volumes flexclone information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.6.7
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
        Write-PScriboMessage "Collecting ONTAP Vserver volumes flexclone information."
    }

    process {
        try {
            $VserverClonedVol = Get-NcVolClone -VserverContext $Vserver -Controller $Array
            if ($VserverClonedVol) {
                foreach ($Item in $VserverClonedVol) {
                    try {
                        $inObj = [ordered] @{
                            'Volume' = $Item.Name
                            'Parent Volume' = $Item.ParentVolume
                            'Volume Type' = $Item.VolumeType.ToUpper()
                            'Parent Snapshot' = $Item.ParentSnapshot
                            'Space Reserve' = $Item.SpaceReserve
                            'Space Guarantee' = ConvertTo-TextYN $Item.SpaceGuaranteeEnabled
                            'Capacity' = $Item.Size | ConvertTo-FormattedNumber -Type DataSize -ErrorAction SilentlyContinue
                            'Available' = $Item.Size - $Item.Used | ConvertTo-FormattedNumber -Type DataSize -ErrorAction SilentlyContinue
                            'Used' = $Item.Used | ConvertTo-FormattedNumber -Type DataSize -ErrorAction SilentlyContinue
                            'Aggregate' = $Item.Aggregate
                        }
                        $VserverObj = [pscustomobject]$inobj

                        if ($Healthcheck.Vserver.Status) {
                            $VserverObj | Where-Object { $_.'Status' -like 'offline' } | Set-Style -Style Warning -Property 'Status'
                        }

                        $TableParams = @{
                            Name = "Cloned Volumes - $($Item.Name)"
                            List = $true
                            ColumnWidths = 25, 75
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $VserverObj | Table @TableParams
                        if ($Healthcheck.Vserver.Status -and ($VserverObj)) {
                            Paragraph "Health Check:" -Bold -Underline
                            BlankLine
                            Paragraph {
                                Text "Best Practice:" -Bold
                                Text "Regularly monitor flexclone volumes to manage storage utilization effectively."
                            }
                            BlankLine
                        }
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning $_.Exception.Message
        }
    }

    end {}

}