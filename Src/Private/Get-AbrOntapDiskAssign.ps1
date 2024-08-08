function Get-AbrOntapDiskAssign {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP disk assign summary information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.6.7
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
        Write-PScriboMessage "Collecting ONTAP disk assignment per node information."
    }

    process {
        try {
            $NodeDiskCount = Get-NcDisk -Controller $Array | ForEach-Object { $_.DiskOwnershipInfo.HomeNodeName } | Group-Object
            if ($NodeDiskCount) {
                $DiskSummary = foreach ($Disks in $NodeDiskCount) {
                    [PSCustomObject] @{
                        'Node' = $Disks.Name
                        'Disk Count' = $Disks | Select-Object -ExpandProperty Count
                    }
                }
                $TableParams = @{
                    Name = "Assigned Disk - $($ClusterInfo.ClusterName)"
                    List = $false
                    ColumnWidths = 50, 50
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $DiskSummary | Table @TableParams
            }
        } catch {
            Write-PScriboMessage -IsWarning $_.Exception.Message
        }
    }

    end {}

}