function Get-AbrOntapNode {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP System Nodes information from the Cluster Management Network
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
        Write-PScriboMessage 'Collecting ONTAP node information.'
    }

    process {
        try {
            $NodeSum = Get-NcNode -Controller $Array
            if ($NodeSum) {
                $OutObj = @()
                foreach ($Nodes in $NodeSum) {
                    try {
                        $inObj = [ordered] @{
                            'Name' = $Nodes.Node
                            'Model' = $Nodes.NodeModel
                            'Id' = $Nodes.NodeSystemId
                            'Serial' = $Nodes.NodeSerialNumber
                            'Uptime' = $Nodes.NodeUptimeTS
                        }
                        $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }
                $TableParams = @{
                    Name = "Nodes - $($ClusterInfo.ClusterName)"
                    List = $false
                    ColumnWidths = 27, 27, 17, 17, 12
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