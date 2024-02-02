function Get-AbrOntapSysConfigWebStatus {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP System Web Service information from the Cluster Management Network
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
        Write-PScriboMessage "Collecting ONTAP System Web Service information."
    }

    process {
        try {
            $Data = Get-NcSystemServicesWebNode -Controller $Array
            $OutObj = @()
            if ($Data) {
                foreach ($Item in $Data) {
                    try {
                        $inObj = [ordered] @{
                            'Node' = $Item.Node
                            'Http Enabled' = ConvertTo-TextYN $Item.HttpEnabled
                            'Http Port' = $Item.HttpPort
                            'Https Port' = $Item.HttpsPort
                            'External' = ConvertTo-TextYN $Item.External
                            'Status' = $TextInfo.ToTitleCase($Item.Status)
                            'Status Code' = $Item.StatusCode
                        }
                        $OutObj += [pscustomobject]$inobj
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }
                if ($Healthcheck.System.DNS) {
                    $OutObj | Where-Object { $_.'Status' -notlike 'Online' } | Set-Style -Style Warning -Property 'Status'
                    $OutObj | Where-Object { $_.'Status Code' -ne 200 } | Set-Style -Style Warning -Property 'Status Code'
                }

                $TableParams = @{
                    Name = "System Web Service - $($ClusterInfo.ClusterName)"
                    List = $false
                    ColumnWidths = 25, 12, 12, 12, 12, 15, 12
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