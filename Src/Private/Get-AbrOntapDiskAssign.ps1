function Get-AbrOntapDiskAssign {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP disk assign summary information from the Cluster Management Network
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
        Write-PScriboMessage 'Collecting ONTAP disk assignment per node information.'
    }

    process {
        try {
            $NodeDiskCount = Get-NcDisk -Controller $Array | ForEach-Object { $_.DiskOwnershipInfo.HomeNodeName } | Group-Object
            if ($NodeDiskCount) {
                $OutObj = @()
                foreach ($Disks in $NodeDiskCount) {
                    $inObj = [ordered] @{
                        'Node' = $Disks.Name
                        'Disk Count' = $Disks | Select-Object -ExpandProperty Count
                    }
                    $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                }
                $TableParams = @{
                    Name = "Assigned Disk - $($ClusterInfo.ClusterName)"
                    List = $false
                    ColumnWidths = 50, 50
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