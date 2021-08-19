function Get-AbrOntapNodes {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP System Nodes information from the Cluster Management Network
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
        Write-PscriboMessage "Collecting ONTAP node information."
    }

    process {
        $NodeSum = Get-NcNode
        if ($NodeSum) {
            $NodeSummary = foreach ($Nodes in $NodeSum) {
                [PSCustomObject] @{
                'Name' = $Nodes.Node
                'Model' = $Nodes.NodeModel
                'Id' = $Nodes.NodeSystemId
                'Serial' = $Nodes.NodeSerialNumber
                'Uptime' = $Nodes.NodeUptimeTS
                }
            }
            $TableParams = @{
                Name = "Node Summary - $($ClusterInfo.ClusterName)"
                List = $false
                ColumnWidths = 27, 27, 17, 17, 12
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $NodeSummary | Table @TableParams
        }
    }

    end {}

}