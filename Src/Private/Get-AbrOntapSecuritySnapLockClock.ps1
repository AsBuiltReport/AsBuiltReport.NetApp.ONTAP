function Get-AbrOntapSecuritySnapLockClock {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP Security Snaplock compliance clock information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.6.3
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
        try {
        $Data =  Get-NcNode -Controller $Array
            $OutObj = @()
            if ($Data) {
                foreach ($Item in $Data) {
                    try {
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
                    catch {
                        Write-PscriboMessage -IsWarning $_.Exception.Message
                    }
                }

                $TableParams = @{
                    Name = "Snaplock Compliance Clock - $($ClusterInfo.ClusterName)"
                    List = $false
                    ColumnWidths = 40, 60
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $OutObj | Table @TableParams
            }
        }
        catch {
            Write-PscriboMessage -IsWarning $_.Exception.Message
        }
    }

    end {}

}