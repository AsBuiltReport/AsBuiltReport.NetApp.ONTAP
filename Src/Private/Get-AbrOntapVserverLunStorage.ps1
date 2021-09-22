function Get-AbrOntapVserverLunStorage {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP vserver lun information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.3.0
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
        Write-PscriboMessage "Collecting ONTAP Vserver lun information."
    }

    process {
        $VserverLun = get-nclun
        $VserverObj = @()
        if ($VserverLun) {
            foreach ($Item in $VserverLun) {
                $lunmap = Get-NcLunMap -Path $Item.Path | Select-Object -ExpandProperty InitiatorGroup
                $lunpath = $Item.Path.split('/')
                $lun = $lunpath[3]
                $available = $Item.Size - $Item.SizeUsed
                $used = ($Item.SizeUsed / $Item.Size) * 100
                $inObj = [ordered] @{
                    'Lun Name' = $lun
                    'Parent Volume' = $Item.Volume
                    'Path' = $Item.Path
                    'Serial Number' = $Item.SerialNumber
                    'Initiator Group' = $lunmap
                    'Home Node ' = $Item.Node
                    'Vserver' = $Item.Vserver
                    'Capacity' = $Item.Size | ConvertTo-FormattedNumber -Type Datasize -ErrorAction SilentlyContinue
                    'Available' = $available | ConvertTo-FormattedNumber -Type Datasize -ErrorAction SilentlyContinue
                    'Used' = $used | ConvertTo-FormattedNumber -Type Percent -ErrorAction SilentlyContinue
                    'OS Type' = $Item.Protocol
                    'IsThin' = ConvertTo-TextYN $Item.Thin
                    'Space Allocation' = Switch ($Item.IsSpaceAllocEnabled) {
                        'True' { 'Enabled' }
                        'False' { 'Disabled' }
                        default {$Item.IsSpaceAllocEnabled}
                    }
                    'Space Reservation' = Switch ($Item.IsSpaceReservationEnabled) {
                        'True' { 'Enabled' }
                        'False' { 'Disabled' }
                        default {$Item.IsSpaceReservationEnabled}
                    }
                    'IsMapped' = ConvertTo-TextYN $Item.Mapped
                    'Status' = Switch ($Item.Online) {
                        'True' { 'Up' }
                        'False' { 'Down' }
                        default {$Item.Online}
                    }
                }
                $VserverObj += [pscustomobject]$inobj
            }
            if ($Healthcheck.Vserver.Status) {
                $VserverObj | Where-Object { $_.'Status' -like 'Down' } | Set-Style -Style Warning -Property 'Status'
                $VserverObj | Where-Object { $_.'Used' -ge 90 } | Set-Style -Style Critical -Property 'Used'
            }

            $TableParams = @{
                Name = "Vserver Lun Information - $($ClusterInfo.ClusterName)"
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