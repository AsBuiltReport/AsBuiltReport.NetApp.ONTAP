function Get-AbrOntapDiskShelfStorage {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP disk shelf storage information from the Cluster Management Network
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
        Write-PScriboMessage 'Collecting ONTAP disk shelf storage information.'
    }

    process {
        try {
            $NodeshelfObj = Get-NcStorageShelf -Controller $Array -ErrorAction SilentlyContinue
            if ($NodeshelfObj) {
                $OutObj = @()
                foreach ($Shelf in $NodeshelfObj) {
                    $inObj = [ordered] @{
                        'Model' = $Shelf.ShelfModel
                        'Connection Type' = $Shelf.ConnectionType
                        'Module Type' = $Shelf.ModuleType
                        'Disk Count' = $Shelf.DiskCount
                        'Serial Number' = $Shelf.SerialNumber
                        'Operational Status' = $Shelf.OpStatus
                        'Shelf Id' = $Shelf.Shelf
                    }
                    $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                }
                if ($Healthcheck.Storage.ShelfStatus) {
                    $OutObj | Where-Object { $_.'Operational Status' -ne 'normal' } | Set-Style -Style Warning -Property 'Operational Status'
                }
                $TableParams = @{
                    Name = "Disk Shelf - $($ClusterInfo.ClusterName)"
                    List = $false
                    ColumnWidths = 18, 13, 12, 11, 22, 14, 10
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $OutObj | Table @TableParams
                if ($Healthcheck.Storage.ShelfStatus -and ($OutObj | Where-Object { $_.'Operational Status' -ne 'normal' })) {
                    Paragraph 'Health Check:' -Bold -Underline
                    BlankLine
                    Paragraph {
                        Text 'Best Practice:' -Bold
                        Text ' All disk shelves should have an working operational status.'
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