function Get-AbrOntapSysConfigEMS {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP System EMS Messages information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.6.2
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
            $Node
    )

    begin {
        Write-PscriboMessage "Collecting ONTAP System EMS Messages information."
    }

    process {
        $Data =  Get-NcEmsMessage -Node $Node -Count 30 -Severity "emergency","alert" -Controller $Array
        $OutObj = @()
        if ($Data) {
            foreach ($Item in $Data) {
                $inObj = [ordered] @{
                    'TimeDT' = $Item.TimeDT
                    'Severity' = $Item.Severity
                    'Event' = $Item.Event
                }
                $OutObj += [pscustomobject]$inobj
            }

            $TableParams = @{
                Name = "HealtCheck - System EMS Messages - $($Node)"
                List = $false
                ColumnWidths = 25, 20, 55
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $OutObj | Table @TableParams
        }
    }

    end {}

}