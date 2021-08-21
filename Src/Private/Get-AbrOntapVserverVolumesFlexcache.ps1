function Get-AbrOntapVserverVolumesFlexcache {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP vserver flexcache volumes information from the Cluster Management Network
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
        Write-PscriboMessage "Collecting ONTAP Vserver flexcache volumes information."
    }

    process {
        #Vserver Flexcache Volume Connected Cache Information
        $Data = Get-NcFlexcacheConnectedCache
        $OutObj = @()
        if ($Data) {
            foreach ($Item in $Data) {
                $VolumeUsage = Get-NcVol -Name $Item.OriginVolume
                $inObj = [ordered] @{
                    'Cache Cluster' = $Item.CacheCluster
                    'Cache Vserver' = $Item.CacheVserver
                    'Cache Volume' = $Item.CacheVolume
                    'Origin Vserver' = $Item.OriginVserver
                    'Origin Volume' = $Item.OriginVolume
                    'Capacity' = $VolumeUsage.TotalSize | ConvertTo-FormattedNumber -Type Datasize -ErrorAction SilentlyContinue
                }
                $OutObj += [pscustomobject]$inobj
            }

            $TableParams = @{
                Name = "Vserver Flexcache Volume Connected Cache Information - $($ClusterInfo.ClusterName)"
                List = $false
                ColumnWidths = 20, 15, 15, 20, 15, 15
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $OutObj | Table @TableParams
        }
        #Vserver Flexcache Volume Information
        $Data = Get-NcFlexcache
        $OutObj = @()
        if ($Data) {
            foreach ($Item in $Data) {
                $inObj = [ordered] @{
                    'Origin Cluster' = $Item.OriginCluster
                    'Origin Vserver' = $Item.OriginVserver
                    'Origin Volume' = $Item.OriginVolume
                    'Cache Vserver' = $Item.Vserver
                    'Cache Volume' = $Item.Volume
                    'Capacity' = $Item.Size | ConvertTo-FormattedNumber -Type Datasize -ErrorAction SilentlyContinue
                }
                $OutObj += [pscustomobject]$inobj
            }

            $TableParams = @{
                Name = "Vserver Flexcache Volume Information - $($ClusterInfo.ClusterName)"
                List = $false
                ColumnWidths = 20, 15, 15, 20, 15, 15
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $OutObj | Table @TableParams
        }
    }

    end {}

}