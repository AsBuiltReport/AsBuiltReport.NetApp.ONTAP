function Get-AbrOntapNodeStorage {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP Node Storage information from the Cluster Management Network
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
        Write-PScriboMessage "Collecting ONTAP Node Storage information."
    }

    process {
        try {
            $Data = Get-NcVol -Controller $Array | Where-Object { $_.Name -eq 'vol0' }
            $OutObj = @()
            if ($Data) {
                foreach ($Item in $Data) {
                    try {
                        $inObj = [ordered] @{
                            'Node' = $Item.Vserver
                            'Aggregate' = $Item.Aggregate
                            'Volume' = $Item.Name
                            'Capacity' = $Item.Totalsize | ConvertTo-FormattedNumber -Type DataSize -ErrorAction SilentlyContinue
                            'Available' = $Item.Available | ConvertTo-FormattedNumber -Type DataSize -ErrorAction SilentlyContinue
                            'Used' = $Item.Used | ConvertTo-FormattedNumber -Type Percent -ErrorAction SilentlyContinue
                        }
                        $OutObj += [pscustomobject]$inobj
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }
                if ($Healthcheck.Node.HW) {
                    $OutObj | Where-Object { $_.'Status' -like 'offline' } | Set-Style -Style Warning -Property 'Status'
                    $OutObj | Where-Object { $_.'Used' -ge 90 } | Set-Style -Style Critical -Property 'Used'
                }

                $TableParams = @{
                    Name = "Node Storage - $($ClusterInfo.ClusterName)"
                    List = $false
                    ColumnWidths = 30, 30, 10, 10, 10, 10
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