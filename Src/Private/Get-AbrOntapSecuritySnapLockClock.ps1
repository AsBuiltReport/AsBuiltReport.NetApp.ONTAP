function Get-AbrOntapSecuritySnapLockClock {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP Security Snaplock compliance clock information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.4.0
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
        Write-PscriboMessage "Collecting ONTAP Security Snaplock compliance clock information."
    }

    process {
        $Data =  Get-NcNode -Controller $Array
        $OutObj = @()
        if ($Data) {
            foreach ($Item in $Data) {
                $SnapLockClock = Get-NcSnaplockComplianceClock $Item.Node -Controller $Array
                $inObj = [ordered] @{
                    'Node Name' = $Item.Node
                    'Compliance Clock' = Switch ($SnapLockClock.FormattedSnaplockComplianceClock) {
                        $Null { 'Uninitialized' }
                        default { $SnapLockClock.FormattedSnaplockComplianceClock }
                    }
                }
                $OutObj += [pscustomobject]$inobj
            }

            $TableParams = @{
                Name = "Snaplock Compliance Clock Information - $($ClusterInfo.ClusterName)"
                List = $false
                ColumnWidths = 40, 60
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $OutObj | Table @TableParams
        }
    }

    end {}

}