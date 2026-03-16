function Get-AbrOntapVserverVolume {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP vserver volumes information from the Cluster Management Network
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
        Write-PScriboMessage 'Collecting ONTAP Vserver volumes information.'
    }

    process {
        try {
            $VserverRootVol = Get-NcVol -VserverContext $Vserver -Controller $Array | Where-Object { $_.JunctionPath -ne '/' -and $_.Name -ne 'vol0' }
            $VserverObj = @()
            if ($VserverRootVol) {
                foreach ($Item in $VserverRootVol) {
                    try {
                        $inObj = [ordered] @{
                            'Volume' = $Item.Name
                            'Status' = $Item.State
                            'Capacity' = ($Item.Totalsize | ConvertTo-FormattedNumber -ErrorAction SilentlyContinue -NumberFormatString 0.0 -Type DataSize) ?? '--'
                            'Available' = ($Item.Available | ConvertTo-FormattedNumber -ErrorAction SilentlyContinue -NumberFormatString 0.0 -Type DataSize) ?? '--'
                            'Used' = ($Item.Used | ConvertTo-FormattedNumber -ErrorAction SilentlyContinue -Type Percent) ?? '--'
                            'Aggregate' = $Item.Aggregate
                        }
                        $VserverObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }
                if ($Healthcheck.Vserver.Status) {
                    $VserverObj | Where-Object { $_.'Status' -like 'offline' } | Set-Style -Style Warning -Property 'Status'
                    $VserverObj | Where-Object { [int]$_.'Used'.Split('%')[0] -ge 75 } | Set-Style -Style Warning -Property 'Used'
                }

                $TableParams = @{
                    Name = "Volume - $($Vserver)"
                    List = $false
                    ColumnWidths = 34, 12, 12, 12, 10, 20
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $VserverObj | Table @TableParams
                if ($Healthcheck.Vserver.Status -and (($VserverObj | Where-Object { $_.'Status' -like 'offline' }) -or ($VserverObj | Where-Object { $_.'Used'.Split('%')[0] -ge 75 }))) {
                    Paragraph 'Health Check:' -Bold -Underline
                    BlankLine
                    if ($VserverObj | Where-Object { $_.'Status' -like 'offline' }) {
                        Paragraph {
                            Text 'Best Practice:' -Bold
                            Text "Ensure all volumes are in 'online' status and monitor volume usage to prevent capacity issues."
                        }
                        BlankLine
                    }
                    if ($VserverObj | Where-Object { [int]$_.'Used'.Split('%')[0] -ge 75 }) {
                        Paragraph {
                            Text 'Best Practice:' -Bold
                            Text 'Ensure all volumes are below 95% usage to prevent capacity issues.'
                        }
                        BlankLine
                    }
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning $_.Exception.Message
        }
    }

    end {}

}