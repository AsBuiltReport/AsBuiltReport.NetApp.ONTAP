function Get-AbrOntapSysConfigEMS {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP System EMS Messages information from the Cluster Management Network
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
        Write-PscriboMessage "Collecting ONTAP System EMS Messages information."
    }

    process {
        $Data =  Get-NcEmsMessage  -Count 30 -Severity "emergency","alert"
        $OutObj = @()
        if ($Data) {
            foreach ($Item in $Data) {
                $inObj = [ordered] @{
                    'Node' = $Item.Node
                    'Severity' = $Item.Severity
                    'TimeDT' = $Item.TimeDT
                    'Event' = $Item.Event
                }
                $OutObj += [pscustomobject]$inobj
            }

            $TableParams = @{
                Name = "HealtCheck - System EMS Messages Information - $($ClusterInfo.ClusterName)"
                List = $false
                ColumnWidths = 20, 12, 23, 45
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $OutObj | Table @TableParams
        }
    }

    end {}

}