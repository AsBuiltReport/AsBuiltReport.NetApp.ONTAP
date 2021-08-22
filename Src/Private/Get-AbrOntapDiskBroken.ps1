function Get-AbrOntapDiskBroken {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP failed disk information from the Cluster Management Network
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
        Write-PscriboMessage "Collecting ONTAP failed disk per node information."
    }

    process {
        $NodeDiskBroken = Get-NcDisk | Where-Object{ $_.DiskRaidInfo.ContainerType -eq "broken" }
        if ($NodeDiskBroken) {
            $DiskFailed = foreach ($DiskBroken in $NodeDiskBroken) {
                    [PSCustomObject] @{
                        'Disk Name' = $DiskBroken.Name
                        'Shelf' = $DiskBroken.Shelf
                        'Bay' = $DiskBroken.Bay
                        'Pool' = $DiskBroken.Pool
                        'Disk Paths' = $DiskBroken.DiskPaths
                        }
                    }
                    if ($Healthcheck.Storage.DiskStatus) {
                        $DiskFailed | Set-Style -Style Critical -Property 'Disk Name','Shelf','Bay','Pool','Disk Paths'
                    }
            $TableParams = @{
                Name = "Failed Disk Summary - $($ClusterInfo.ClusterName)"
                List = $false
                ColumnWidths = 26, 13, 13, 13, 35
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $DiskFailed | Table @TableParams
        }
    }

    end {}

}