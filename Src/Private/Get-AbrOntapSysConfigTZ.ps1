function Get-AbrOntapSysConfigTZ {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP System TimeZone information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.6.2
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
        Write-PscriboMessage "Collecting ONTAP System TimeZone information."
    }

    process {
        $Data =  Get-NcTimezone -Controller $Array
        $OutObj = @()
        if ($Data) {
            foreach ($Item in $Data) {
                $Time = Get-NcTime -Controller $Array | Select-Object -ExpandProperty UtcTime
                $CurrentTime = Get-UnixDate($Time)
                $inObj = [ordered] @{
                    'Timezone' = $Item.Timezone
                    'Timezone UTC' = $Item.TimezoneUtc
                    'Timezone Version' = $Item.TimezoneVersion
                    'Current Time' = $CurrentTime
                }
                $OutObj += [pscustomobject]$inobj
            }

            $TableParams = @{
                Name = "System TimeZone - $($ClusterInfo.ClusterName)"
                List = $false
                ColumnWidths = 30, 20, 20, 30
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $OutObj | Table @TableParams
        }
    }

    end {}

}