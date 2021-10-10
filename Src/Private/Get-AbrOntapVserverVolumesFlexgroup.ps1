function Get-AbrOntapVserverVolumesFlexgroup {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP vserver flexgroup volumes information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.4.0
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
        Write-PscriboMessage "Collecting ONTAP Vserver flexgroup volumes information."
    }

    process {
        $Data = Get-NcVol -VserverContext $Vserver | Where-Object {$_.JunctionPath -ne '/' -and $_.Name -ne 'vol0' -and $_.VolumeStateAttributes.IsFlexgroup -eq "True"}
        $OutObj = @()
        if ($Data) {
            foreach ($Item in $Data) {
                $inObj = [ordered] @{
                    'Volume' = $Item.Name
                    'Status' = $Item.State
                    'Capacity' = $Item.Totalsize | ConvertTo-FormattedNumber -Type DataSize -ErrorAction SilentlyContinue
                }
                $OutObj += [pscustomobject]$inobj
            }
            if ($Healthcheck.Vserver.Status) {
                $OutObj | Where-Object { $_.'Status' -like 'offline' } | Set-Style -Style Warning -Property 'Status'
            }

            $TableParams = @{
                Name = "Vserver Flexgroup Volume Information - $($Vserver)"
                List = $false
                ColumnWidths = 50, 25, 25
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $OutObj | Table @TableParams
        }
    }

    end {}

}