function Get-AbrOntapDiskShelf {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP disk shelf information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.5.0
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
        Write-PscriboMessage "Collecting ONTAP disk shelf information."
    }

    process {
        $NodeSum = Get-NcNode -Controller $Array
        if ($NodeSum) {
            $ShelfInventory = foreach ($Nodes in $NodeSum) {
                $Nodeshelf = Get-NcShelf -NodeName $Nodes.Node -Controller $Array
                if ($Nodeshelf) {
                    [PSCustomObject] @{
                        'Node Name' = $Nodeshelf.NodeName
                        'Channel' = $Nodeshelf.ChannelName
                        'Shelf Name' = $Nodeshelf.ShelfName
                        'Shelf ID' = $Nodeshelf.ShelfId
                        'State' = $Nodeshelf.ShelfState
                        'Type' = $Nodeshelf.ShelfType
                        'Firmware' = $Nodeshelf.FirmwareRevA+$Nodeshelf.FirmwareRevB
                        'Bay Count' = $Nodeshelf.ShelfBayCount
                    }
                }
            }
            if ($Healthcheck.Storage.ShelfStatus) {
                $ShelfInventory | Where-Object { $_.'State' -like 'offline' -or $_.'State' -like 'missing' } | Set-Style -Style Critical -Property 'State'
                $ShelfInventory | Where-Object { $_.'State' -like 'unknown' -or $_.'State' -like 'no-status' } | Set-Style -Style Warning -Property 'State'
            }
            $TableParams = @{
                Name = "Shelf Inventory - $($ClusterInfo.ClusterName)"
                List = $true
                ColumnWidths = 35, 65
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $ShelfInventory | Table @TableParams
        }
    }

    end {}

}