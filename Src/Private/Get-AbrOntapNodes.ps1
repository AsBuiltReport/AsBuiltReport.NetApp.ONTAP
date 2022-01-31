function Get-AbrOntapNode {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP System Nodes information from the Cluster Management Network
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
        Write-PscriboMessage "Collecting ONTAP node information."
    }

    process {
        try {
            $NodeSum = Get-NcNode -Controller $Array
            if ($NodeSum) {
                $NodeSummary = foreach ($Nodes in $NodeSum) {
                    try {
                        [PSCustomObject] @{
                        'Name' = $Nodes.Node
                        'Model' = $Nodes.NodeModel
                        'Id' = $Nodes.NodeSystemId
                        'Serial' = $Nodes.NodeSerialNumber
                        'Uptime' = $Nodes.NodeUptimeTS
                        }
                    }
                    catch {
                        Write-PscriboMessage -IsWarning $_.Exception.Message
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
                $NodeSummary | Table @TableParams
            }
        }
        catch {
            Write-PscriboMessage -IsWarning $_.Exception.Message
        }
    }

    end {}

}