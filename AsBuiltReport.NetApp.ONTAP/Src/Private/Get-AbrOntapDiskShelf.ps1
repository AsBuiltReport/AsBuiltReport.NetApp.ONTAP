function Get-AbrOntapDiskShelf {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP disk shelf information from the Cluster Management Network
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
        Write-PScriboMessage 'Collecting ONTAP disk shelf information.'
    }

    process {
        try {
            $NodeSum = Get-NcNode -Controller $Array
            if ($NodeSum) {
                foreach ($Nodes in $NodeSum) {
                    try {
                        $Nodeshelf = Get-NcShelf -NodeName $Nodes.Node -Controller $Array -ErrorAction SilentlyContinue
                        if ($Nodeshelf) {
                            Section -ExcludeFromTOC -Style NOTOCHeading4 $($Nodes.Node) {
                                $OutObj = @()
                                foreach ($Shelf in $Nodeshelf) {
                                    $inObj = [ordered] @{
                                        'Channel' = $Shelf.ChannelName
                                        'Shelf Name' = $Shelf.ShelfName
                                        'Shelf ID' = $Shelf.ShelfId
                                        'Module' = $Shelf.Module
                                        'Module State' = $Shelf.ModuleState
                                        'State' = $Shelf.ShelfState
                                        'Type' = $Shelf.ShelfType
                                        'Firmware' = ($Shelf.FirmwareRevA + $Shelf.FirmwareRevB) ?? '--'
                                    }
                                    $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                }
                                if ($Healthcheck.Storage.ShelfStatus) {
                                    $OutObj | Where-Object { $_.'State' -like 'offline' -or $_.'State' -like 'missing' } | Set-Style -Style Critical -Property 'State'
                                    $OutObj | Where-Object { $_.'State' -like 'unknown' -or $_.'State' -like 'no-status' } | Set-Style -Style Warning -Property 'State'
                                }
                                $TableParams = @{
                                    Name = "Storage Shelf - $($Nodes.Node)"
                                    List = $false
                                    ColumnWidths = 13, 13, 13, 13, 12, 12, 12, 12
                                }
                                if ($Report.ShowTableCaptions) {
                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                }
                                $OutObj | Table @TableParams
                                if ($Healthcheck.Storage.ShelfStatus -and ($OutObj | Where-Object { $_.'State' -like 'offline' -or $_.'State' -like 'missing' })) {
                                    Paragraph 'Health Check:' -Bold -Underline
                                    BlankLine
                                    Paragraph {
                                        Text 'Best Practice:' -Bold
                                        Text 'Ensure all disk shelves are online and operational. Investigate any shelves marked as offline or missing.'
                                    }
                                    BlankLine
                                }
                            }
                        }
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning $_.Exception.Message
        }
    }

    end {}

}