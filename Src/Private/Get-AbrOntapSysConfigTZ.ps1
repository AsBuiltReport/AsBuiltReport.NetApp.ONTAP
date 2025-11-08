function Get-AbrOntapSysConfigTZ {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP System TimeZone information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.6.7
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
        Write-PScriboMessage "Collecting ONTAP System TimeZone information."
    }

    process {
        try {
            $Data = Get-NcTimezone -Controller $Array
            $OutObj = @()
            if ($Data) {
                foreach ($Item in $Data) {
                    try {
                        $Time = (Get-NcTime -Controller $Array).UtcTime[0]
                        $CurrentTime = Get-UnixDate($Time)
                        $inObj = [ordered] @{
                            'Timezone' = $Item.Timezone
                            'Timezone UTC' = $Item.TimezoneUtc
                            'Timezone Version' = $Item.TimezoneVersion
                            'Current Time' = $CurrentTime
                        }
                        $OutObj += [pscustomobject]$inobj
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }

                $TableParams = @{
                    Name = "TimeZone - $($ClusterInfo.ClusterName)"
                    List = $false
                    ColumnWidths = 30, 20, 20, 30
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $OutObj | Table @TableParams
            }
        } catch {
            Write-PScriboMessage -IsWarning $_.Exception.Message
        }
    }

    end {}

}