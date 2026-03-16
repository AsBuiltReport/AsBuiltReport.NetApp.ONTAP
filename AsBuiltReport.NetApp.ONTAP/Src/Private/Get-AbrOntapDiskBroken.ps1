function Get-AbrOntapDiskBroken {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP failed disk information from the Cluster Management Network
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
        Write-PScriboMessage 'Collecting ONTAP failed disk per node information.'
    }

    process {
        try {
            $NodeDiskBroken = Get-NcDisk -Controller $Array | Where-Object { $_.DiskRaidInfo.ContainerType -eq 'broken' }
            if ($NodeDiskBroken) {
                $OutObj = @()
                foreach ($DiskBroken in $NodeDiskBroken) {
                    $inObj = [ordered] @{
                        'Disk Name' = $DiskBroken.Name
                        'Shelf' = $DiskBroken.Shelf
                        'Bay' = $DiskBroken.Bay
                        'Pool' = $DiskBroken.Pool
                        'Disk Paths' = $DiskBroken.DiskPaths
                    }
                    $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                }
                if ($Healthcheck.Storage.DiskStatus) {
                    $OutObj | Set-Style -Style Critical -Property 'Disk Name', 'Shelf', 'Bay', 'Pool', 'Disk Paths'
                }
                $TableParams = @{
                    Name = "Failed Disk - $($ClusterInfo.ClusterName)"
                    List = $false
                    ColumnWidths = 26, 13, 13, 13, 35
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $OutObj | Table @TableParams
                if ($Healthcheck.Storage.DiskStatus -and ($OutObj)) {
                    Paragraph 'Health Check:' -Bold -Underline
                    BlankLine
                    Paragraph {
                        Text 'Best Practice:' -Bold
                        Text 'Review the failed disk information above. It is recommended to replace any broken disks promptly to maintain data integrity and system performance.'
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