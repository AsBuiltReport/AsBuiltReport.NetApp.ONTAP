function Get-AbrOntapVserverVolumesFlexclone {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP vserver volumes flexclone information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.4.0
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
        Write-PscriboMessage "Collecting ONTAP Vserver volumes flexclone information."
    }

    process {
        $VserverClonedVol = Get-NcVolClone
        $VserverObj = @()
        if ($VserverClonedVol) {
            foreach ($Item in $VserverClonedVol) {
                $inObj = [ordered] @{
                    'Volume' = $Item.Name
                    'Vserver' = $Item.Vserver
                    'ParentVolume' = $Item.ParentVolume
                    'Volume Type' = $Item.VolumeType.ToUpper()
                    'Parent Snapshot' = $Item.ParentSnapshot
                    'Space Reserve' = $Item.SpaceReserve
                    'Space Guarantee' = ConvertTo-TextYN $Item.SpaceGuaranteeEnabled
                    'Capacity' = $Item.Size | ConvertTo-FormattedNumber -Type DataSize -ErrorAction SilentlyContinue
                    'Available' = $Item.Size - $Item.Used | ConvertTo-FormattedNumber -Type DataSize -ErrorAction SilentlyContinue
                    'Used' = $Item.Used | ConvertTo-FormattedNumber -Type DataSize -ErrorAction SilentlyContinue
                    'Aggregate' = $Item.Aggregate
                }
                $VserverObj += [pscustomobject]$inobj
            }
            if ($Healthcheck.Vserver.Status) {
                $VserverObj | Where-Object { $_.'Status' -like 'offline' } | Set-Style -Style Warning -Property 'Status'
            }

            $TableParams = @{
                Name = "Vserver Cloned Volumes Information - $($ClusterInfo.ClusterName)"
                List = $true
                ColumnWidths = 25, 75
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $VserverObj | Table @TableParams
        }
    }

    end {}

}