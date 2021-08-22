function Get-AbrOntapVserverVolumes {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP vserver volumes information from the Cluster Management Network
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
        Write-PscriboMessage "Collecting ONTAP Vserver volumes information."
    }

    process {
        $VserverRootVol = Get-NcVol | Where-Object {$_.JunctionPath -ne '/' -and $_.Name -ne 'vol0'}
        $VserverObj = @()
        if ($VserverRootVol) {
            foreach ($Item in $VserverRootVol) {
                $inObj = [ordered] @{
                    'Volume' = $Item.Name
                    'Vserver' = $Item.Vserver
                    'Status' = $Item.State
                    'Capacity' = $Item.Totalsize | ConvertTo-FormattedNumber -Type DataSize -ErrorAction SilentlyContinue
                    'Available' = $Item.Available | ConvertTo-FormattedNumber -Type DataSize -ErrorAction SilentlyContinue
                    'Used' = $Item.Used | ConvertTo-FormattedNumber -Type Percent -ErrorAction SilentlyContinue
                    'Aggregate' = $Item.Aggregate
                }
                $VserverObj += [pscustomobject]$inobj
            }
            if ($Healthcheck.Vserver.Status) {
                $VserverObj | Where-Object { $_.'Status' -like 'offline' } | Set-Style -Style Warning -Property 'Status'
            }

            $TableParams = @{
                Name = "Vserver Volume Information - $($ClusterInfo.ClusterName)"
                List = $false
                ColumnWidths = 27, 15, 10, 10, 10, 8, 20
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $VserverObj | Table @TableParams
        }
    }

    end {}

}