function Get-AbrOntapVserverVolume {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP vserver volumes information from the Cluster Management Network
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
        Write-PScriboMessage "Collecting ONTAP Vserver volumes information."
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
                            'Capacity' = $Item.Totalsize | ConvertTo-FormattedNumber -Type DataSize -ErrorAction SilentlyContinue
                            'Available' = $Item.Available | ConvertTo-FormattedNumber -Type DataSize -ErrorAction SilentlyContinue
                            'Used' = $Item.Used | ConvertTo-FormattedNumber -Type Percent -ErrorAction SilentlyContinue
                            'Aggregate' = $Item.Aggregate
                        }
                        $VserverObj += [pscustomobject]$inobj
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }
                if ($Healthcheck.Vserver.Status) {
                    $VserverObj | Where-Object { $_.'Status' -like 'offline' } | Set-Style -Style Warning -Property 'Status'
                    $VserverObj | Where-Object { $_.'Used' -ge 75 } | Set-Style -Style Warning -Property 'Used'
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
            }
        } catch {
            Write-PScriboMessage -IsWarning $_.Exception.Message
        }
    }

    end {}

}