function Get-AbrOntapVserverLunStorage {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP vserver lun information from the Cluster Management Network
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
        Write-PScriboMessage "Collecting ONTAP Vserver lun information."
    }

    process {
        try {
            $VserverLun = Get-NcLun -VserverContext $Vserver -Controller $Array
            $VserverObj = @()
            if ($VserverLun) {
                foreach ($Item in $VserverLun) {
                    try {
                        $lunmap = Get-NcLunMap -Path $Item.Path -Controller $Array | Select-Object -ExpandProperty InitiatorGroup
                        $lunpath = $Item.Path.split('/')
                        $lun = $lunpath[3]
                        $available = $Item.Size - $Item.SizeUsed
                        $used = ($Item.SizeUsed / $Item.Size) * 100
                        $inObj = [ordered] @{
                            'Lun Name' = $lun
                            'Parent Volume' = $Item.Volume
                            'Path' = $Item.Path
                            'Serial Number' = $Item.SerialNumber
                            'Initiator Group' = switch (($lunmap).count) {
                                0 { "None" }
                                default { $lunmap }
                            }
                            'Home Node ' = $Item.Node
                            'Capacity' = $Item.Size | ConvertTo-FormattedNumber -Type Datasize -ErrorAction SilentlyContinue
                            'Available' = $available | ConvertTo-FormattedNumber -Type Datasize -ErrorAction SilentlyContinue
                            'Used' = $used | ConvertTo-FormattedNumber -Type Percent -ErrorAction SilentlyContinue
                            'OS Type' = $Item.Protocol
                            'Is Thin' = ConvertTo-TextYN $Item.Thin
                            'Space Allocation' = switch ($Item.IsSpaceAllocEnabled) {
                                'True' { 'Enabled' }
                                'False' { 'Disabled' }
                                default { $Item.IsSpaceAllocEnabled }
                            }
                            'Space Reservation' = switch ($Item.IsSpaceReservationEnabled) {
                                'True' { 'Enabled' }
                                'False' { 'Disabled' }
                                default { $Item.IsSpaceReservationEnabled }
                            }
                            'Is Mapped' = ConvertTo-TextYN $Item.Mapped
                            'Status' = switch ($Item.Online) {
                                'True' { 'Up' }
                                'False' { 'Down' }
                                default { $Item.Online }
                            }
                        }
                        $VserverObj = [pscustomobject]$inobj

                        if ($Healthcheck.Vserver.Status) {
                            $VserverObj | Where-Object { $_.'Status' -like 'Down' } | Set-Style -Style Warning -Property 'Status'
                            $VserverObj | Where-Object { $_.'Used' -ge 90 } | Set-Style -Style Critical -Property 'Used'
                            $VserverObj | Where-Object { $_.'Is Mapped' -eq 'No' } | Set-Style -Style Warning -Property 'Is Mapped'
                        }

                        $TableParams = @{
                            Name = "Lun - $($lun)"
                            List = $true
                            ColumnWidths = 25, 75
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $VserverObj | Table @TableParams
                        if ($Healthcheck.Vserver.Status -and ($VserverObj | Where-Object { $_.'Status' -like 'Down' })) {
                            Paragraph "Health Check:" -Bold -Underline
                            BlankLine
                            Paragraph {
                                Text "Best Practice:" -Bold
                                Text "Ensure that all LUNs are operational to maintain optimal storage connectivity."
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