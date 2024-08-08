function Get-AbrOntapVserverVolumesFlexcache {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP vserver flexcache volumes information from the Cluster Management Network
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
        Write-PScriboMessage "Collecting ONTAP Vserver flexcache volumes information."
    }

    process {
        try {
            #Vserver Flexcache Volume Connected Cache Information
            $Data = Get-NcFlexcacheConnectedCache -VserverContext $Vserver -Controller $Array
            $OutObj = @()
            if ($Data) {
                foreach ($Item in $Data) {
                    try {
                        $VolumeUsage = Get-NcVol -Name $Item.OriginVolume -Controller $Array
                        $inObj = [ordered] @{
                            'Cache Cluster' = $Item.CacheCluster
                            'Cache Vserver' = $Item.CacheVserver
                            'Cache Volume' = $Item.CacheVolume
                            'Origin Vserver' = $Item.OriginVserver
                            'Origin Volume' = $Item.OriginVolume
                            'Capacity' = $VolumeUsage.TotalSize | ConvertTo-FormattedNumber -Type Datasize -ErrorAction SilentlyContinue
                        }
                        $OutObj += [pscustomobject]$inobj
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }

                $TableParams = @{
                    Name = "Flexcache Volume Connected Cache - $($Vserver)"
                    List = $false
                    ColumnWidths = 20, 15, 15, 20, 15, 15
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $OutObj | Table @TableParams
            }
            #Vserver Flexcache Volume Information
            try {
                $Data = Get-NcFlexcache -VserverContext $Vserver -Controller $Array
                $OutObj = @()
                if ($Data) {
                    foreach ($Item in $Data) {
                        try {
                            $inObj = [ordered] @{
                                'Origin Cluster' = $Item.OriginCluster
                                'Origin Vserver' = $Item.OriginVserver
                                'Origin Volume' = $Item.OriginVolume
                                'Cache Vserver' = $Item.Vserver
                                'Cache Volume' = $Item.Volume
                                'Capacity' = $Item.Size | ConvertTo-FormattedNumber -Type Datasize -ErrorAction SilentlyContinue
                            }
                            $OutObj += [pscustomobject]$inobj
                        } catch {
                            Write-PScriboMessage -IsWarning $_.Exception.Message
                        }
                    }

                    $TableParams = @{
                        Name = "Flexcache Volume - $($Vserver)"
                        List = $false
                        ColumnWidths = 20, 15, 15, 20, 15, 15
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $OutObj | Table @TableParams
                }
            } catch {
                Write-PScriboMessage -IsWarning $_.Exception.Message
            }
        } catch {
            Write-PScriboMessage -IsWarning $_.Exception.Message
        }
    }

    end {}

}