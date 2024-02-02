function Get-AbrOntapVserverCGLun {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP Vserver Consistency Groups Luns information from the Cluster Management Network
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
        $CGObj
    )

    begin {
        Write-PScriboMessage "Collecting ONTAP Vserver Consistency Groups lun information."
    }

    process {
        try {
            $LunData = $CGObj.luns
            $CGLunObj = @()
            if ($LunData) {
                foreach ($Item in $LunData) {
                    try {
                        $inObj = [ordered] @{
                            'Name' = $Item.Name.Split('/')[3]
                            'Capacity' = Switch ([string]::IsNullOrEmpty($Item.space.size)) {
                                $true { '-' }
                                $false { $Item.space.size | ConvertTo-FormattedNumber -Type Datasize -ErrorAction SilentlyContinue }
                                default { '-' }
                            }
                            'Used' = Switch ([string]::IsNullOrEmpty($Item.space.used)) {
                                $true { '-' }
                                $false { $Item.space.used | ConvertTo-FormattedNumber -Type Datasize -ErrorAction SilentlyContinue }
                                default { '-' }
                            }
                            'OS Type' = ConvertTo-EmptyToFiller $Item.os_type
                            'Volume State' = $Item.status.container_state
                            'Mapped' = ConvertTo-TextYN $Item.status.mapped
                            'Read Only' = ConvertTo-TextYN $Item.status.read_only
                            'State' = $Item.status.state


                        }
                        $CGLunObj += [pscustomobject]$inobj
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }

                if ($Healthcheck.Vserver.CG) {
                    $CGLunObj | Where-Object { $_.'Volume State' -ne 'online' } | Set-Style -Style Warning -Property 'Volume State'
                    $CGLunObj | Where-Object { $_.'Mapped' -eq 'No' } | Set-Style -Style Warning -Property 'Mapped'
                    $CGLunObj | Where-Object { $_.'Read Only' -eq 'Yes' } | Set-Style -Style Warning -Property 'Read Only'
                    $CGLunObj | Where-Object { $_.'State' -eq 'offline' } | Set-Style -Style Warning -Property 'State'
                }

                $TableParams = @{
                    Name = "Consistency Group Luns - $($CGObj.Name)"
                    List = $false
                    ColumnWidths = 30, 10, 9, 10, 11, 10, 10, 10
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $CGLunObj | Sort-Object -Property Name | Table @TableParams
            }
        } catch {
            Write-PScriboMessage -IsWarning $_.Exception.Message
        }
    }

    end {}

}