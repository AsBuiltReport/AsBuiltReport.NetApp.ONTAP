function Get-AbrOntapNodeStorage {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP Node Storage information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.6.12
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
        Write-PScriboMessage 'Collecting ONTAP Node Storage information.'
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
                            'Capacity' = ($Item.Totalsize | ConvertTo-FormattedNumber -NumberFormatString 0.0 -Type DataSize) ?? '--'
                            'Available' = ($Item.Available | ConvertTo-FormattedNumber -NumberFormatString 0.0 -Type DataSize) ?? '--'
                            'Used' = ($Item.Used | ConvertTo-FormattedNumber -Type Percent) ?? '--'
                        }
                        $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
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
                if ($Healthcheck.Node.HW -and (($OutObj | Where-Object { $_.'Status' -like 'offline' }) -or ($OutObj | Where-Object { $_.'Used' -ge 90 }))) {
                    Paragraph 'Health Check:' -Bold -Underline
                    BlankLine
                    Paragraph {
                        Text 'Best Practice:' -Bold
                        Text 'Ensure that all nodes are online and that storage usage is within acceptable limits.'
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