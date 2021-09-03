function Get-AbrOntapDiskAssign {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP disk assign summary information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.3.0
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
        Write-PscriboMessage "Collecting ONTAP disk assignment per node information."
    }

    process {
        $NodeDiskCount = get-ncdisk | ForEach-Object{ $_.DiskOwnershipInfo.HomeNodeName } | Group-Object
        if ($NodeDiskCount) {
            $DiskSummary = foreach ($Disks in $NodeDiskCount) {
                [PSCustomObject] @{
                    'Node' = $Disks.Name
                    'Disk Count' = $Disks | Select-Object -ExpandProperty Count
                    }
            }
            $TableParams = @{
                Name = "Assigned Disk Summary - $($ClusterInfo.ClusterName)"
                List = $false
                ColumnWidths = 50, 50
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $DiskSummary | Table @TableParams
        }
        $Node = Get-NcNode
        if ($Node) {
            $DiskSummary = foreach ($Nodes in $Node) {
                $DiskOwner = Get-NcDiskOwner -Node $Nodes.Node
                [PSCustomObject] @{
                    'Disk' = $DiskOwner.Name
                    'Owner' = $DiskOwner.Owner
                    'Owner Id' = $DiskOwner.OwnerId
                    'Home' = $DiskOwner.Home
                    'Home Id' = $DiskOwner.HomeId
                    'Type' = $DiskOwner.Type
                    }
            }
            $TableParams = @{
                Name = "Disk Owner Summary - $($ClusterInfo.ClusterName)"
                List = $false
                ColumnWidths = 20, 20, 15, 20, 15, 10
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $DiskSummary | Table @TableParams
        }
    }

    end {}

}