function Get-AbrOntapEfficiencyVolSisStatus {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP Volume Deduplication information from the Cluster Management Network
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
        Write-PScriboMessage 'Collecting ONTAP Volume Deduplication information.'
    }

    process {
        try {
            $Data = Get-NcSis -VserverContext $Vserver -Controller $Array | Where-Object { $_.Path -notlike '*vol0*' }
            $OutObj = @()
            if ($Data) {
                foreach ($Item in $Data) {
                    try {
                        $inObj = [ordered] @{
                            'Volume' = ($Item.Path.split('/'))[2] ?? '--'
                            'State' = ($Item.State -eq 'enabled') ? 'Enabled': 'Disabled'
                            'Status' = $Item.Status
                            'Schedule Or Policy' = $Item.ScheduleOrPolicy
                            'Progress' = $Item.Progress
                        }
                        $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }
                if ($Healthcheck.Storage.Efficiency) {
                    $OutObj | Where-Object { $_.'State' -like 'Disabled' } | Set-Style -Style Warning -Property 'State'
                }

                $TableParams = @{
                    Name = "Volume Deduplication - $($Vserver)"
                    List = $false
                    ColumnWidths = 30, 15, 15, 20, 20
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $OutObj | Table @TableParams
                if ($Healthcheck.Storage.Efficiency -and ($OutObj | Where-Object { $_.'State' -like 'Disabled' })) {
                    Paragraph 'Health Check:' -Bold -Underline
                    BlankLine
                    Paragraph {
                        Text 'Best Practice:' -Bold
                        Text 'Ensure that volume deduplication is enabled on volumes where data reduction is beneficial to optimize storage efficiency.'
                    }
                    BlankLine
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning $_.Exception.Message
        }
    }

    end {}

}