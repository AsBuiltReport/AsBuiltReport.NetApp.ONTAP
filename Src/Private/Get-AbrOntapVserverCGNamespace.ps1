function Get-AbrOntapVserverCGNamespace {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP Vserver Consistency Groups Namespace information from the Cluster Management Network
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
        Write-PScriboMessage "Collecting ONTAP Vserver Consistency Groups namespace information."
    }

    process {
        try {
            $NamespaceData = $CGObj.namespaces
            $CGNamespaceObj = @()
            if ($NamespaceData) {
                foreach ($Item in $NamespaceData) {
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
                        $CGNamespaceObj += [pscustomobject]$inobj
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }

                if ($Healthcheck.Vserver.CG) {
                    $CGNamespaceObj | Where-Object { $_.'Volume State' -ne 'online' } | Set-Style -Style Warning -Property 'Volume State'
                    $CGNamespaceObj | Where-Object { $_.'Mapped' -eq 'No' } | Set-Style -Style Warning -Property 'Mapped'
                    $CGNamespaceObj | Where-Object { $_.'Read Only' -eq 'Yes' } | Set-Style -Style Warning -Property 'Read Only'
                    $CGNamespaceObj | Where-Object { $_.'State' -eq 'offline' } | Set-Style -Style Warning -Property 'State'
                }

                $TableParams = @{
                    Name = "Consistency Group Namespace - $($CGObj.Name)"
                    List = $false
                    ColumnWidths = 30, 10, 9, 10, 11, 10, 10, 10
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $CGNamespaceObj | Sort-Object -Property Name | Table @TableParams
            }
        } catch {
            Write-PScriboMessage -IsWarning $_.Exception.Message
        }
    }

    end {}

}