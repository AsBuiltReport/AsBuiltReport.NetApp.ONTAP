function Get-AbrOntapVserverLunStorage {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP vserver lun information from the Cluster Management Network
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
        Write-PScriboMessage 'Collecting ONTAP Vserver lun information.'
    }

    process {
        try {
            $VserverLun = Get-NcLun -VserverContext $Vserver -Controller $Array
            $VserverObj = @()
            if ($VserverLun) {
                foreach ($Item in $VserverLun) {
                    try {
                        $lunmap = Get-NcLunMap -Path $Item.Path -Controller $Array | Select-Object -ExpandProperty InitiatorGroup
                        $lun = $Item.Path.split('/')[3]
                        $inObj = [ordered] @{
                            'Lun Name' = $lun
                            'Parent Volume' = $Item.Volume
                            'Path' = $Item.Path
                            'Serial Number' = $Item.SerialNumber
                            'Initiator Group' = ($lunmap.count -eq 0) ? 'None': $lunmap
                            'Home Node ' = $Item.Node
                            'Capacity' = ($Item.Size | ConvertTo-FormattedNumber -ErrorAction SilentlyContinue -NumberFormatString 0.0 -Type Datasize) ?? '--'
                            'Available' = (($Item.Size - $Item.SizeUsed) | ConvertTo-FormattedNumber -ErrorAction SilentlyContinue -NumberFormatString 0.0 -Type Datasize) ?? '--'
                            'Used' = ((($Item.SizeUsed / $Item.Size) * 100) | ConvertTo-FormattedNumber -ErrorAction SilentlyContinue -Type Percent) ?? '--'
                            'OS Type' = $Item.Protocol
                            'Is Thin' = $Item.Thin
                            'Space Allocation' = $Item.IsSpaceAllocEnabled -eq $True ? 'Enabled': 'Disabled'
                            'Space Reservation' = $Item.IsSpaceReservationEnabled -eq $True ? 'Enabled': 'Disabled'
                            'Is Mapped' = $Item.Mapped
                            'Status' = $Item.Online -eq $True ? 'Up': 'Down'
                        }
                        $VserverObj = [pscustomobject](ConvertTo-HashToYN $inObj)

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
                            Paragraph 'Health Check:' -Bold -Underline
                            BlankLine
                            Paragraph {
                                Text 'Best Practice:' -Bold
                                Text 'Ensure that all LUNs are operational to maintain optimal storage connectivity.'
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