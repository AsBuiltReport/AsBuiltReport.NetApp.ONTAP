function Get-AbrOntapVserverCGSummary {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP Vserver Consistency Groups information from the Cluster Management Network
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
        Write-PScriboMessage "Collecting ONTAP Vserver Consistency Groups information."
    }

    process {
        try {
            $VserverData = Get-NetAppOntapAPI -uri "/api/application/consistency-groups?svm=$Vserver&fields=**&return_records=true&return_timeout=15"
            $VserverObj = @()
            if ($VserverData) {
                foreach ($Item in $VserverData) {
                    try {
                        $inObj = [ordered] @{
                            'Name' = $Item.Name
                            'Capacity' = Switch ([string]::IsNullOrEmpty($Item.space.size)) {
                                $true { '-' }
                                $false { $Item.space.size | ConvertTo-FormattedNumber -Type Datasize -ErrorAction SilentlyContinue }
                                default { '-' }
                            }
                            'Available' = Switch ([string]::IsNullOrEmpty($Item.space.available)) {
                                $true { '-' }
                                $false { $Item.space.available | ConvertTo-FormattedNumber -Type Datasize -ErrorAction SilentlyContinue }
                                default { '-' }
                            }
                            'Used' = Switch ([string]::IsNullOrEmpty($Item.space.used)) {
                                $true { '-' }
                                $false { $Item.space.used | ConvertTo-FormattedNumber -Type Datasize -ErrorAction SilentlyContinue }
                                default { '-' }
                            }
                            'Replicated' = ConvertTo-TextYN $Item.replicated
                            'Lun Count' = Switch ([string]::IsNullOrEmpty($Item.luns.name)) {
                                $true { '-' }
                                $false { ($Item.luns.name).count }
                                default { '-' }
                            }
                        }
                        $VserverObj += [pscustomobject]$inobj
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }

                $TableParams = @{
                    Name = "Consistency Groups - $($Vserver)"
                    List = $false
                    ColumnWidths = 40, 12, 12, 12, 12, 12
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $VserverObj | Table @TableParams
            }
        } catch {
            Write-PScriboMessage -IsWarning $_.Exception.Message
        }
    }

    end {}

}