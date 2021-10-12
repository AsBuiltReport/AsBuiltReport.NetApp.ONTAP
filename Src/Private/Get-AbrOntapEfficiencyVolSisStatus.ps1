function Get-AbrOntapEfficiencyVolSisStatus {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP Volume Deduplication information from the Cluster Management Network
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
        Write-PscriboMessage "Collecting ONTAP Volume Deduplication information."
    }

    process {
        $Data = Get-NcSis -VserverContext $Vserver -Controller $Array | Where-Object {$_.Path -notlike '*vol0*'}
        $OutObj = @()
        if ($Data) {
            foreach ($Item in $Data) {
                $Volume = $Item.Path.split('/')
                $inObj = [ordered] @{
                    'Volume' = $Volume[2]
                    'State' = Switch ($Item.State) {
                        'enabled' { 'Enabled' }
                        'disabled' { 'Disabled' }
                        default {$Item.State}
                    }
                    'Status' = $Item.Status
                    'Schedule Or Policy' = $Item.ScheduleOrPolicy
                    'Progress' = $Item.Progress
                }
                $OutObj += [pscustomobject]$inobj
            }

            $TableParams = @{
                Name = "Volume Deduplication Information - $($Vserver)"
                List = $false
                ColumnWidths = 30, 15, 15, 20, 20
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $OutObj | Table @TableParams
        }
    }

    end {}

}