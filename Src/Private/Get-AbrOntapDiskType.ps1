function Get-AbrOntapDiskType {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP disk type information from the Cluster Management Network
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
        Write-PscriboMessage "Collecting ONTAP disk type per node information."
    }

    process {
        $NodeDiskContainerType = Get-NcDisk | ForEach-Object{ $_.DiskRaidInfo.ContainerType } | Group-Object
        if ($NodeDiskContainerType) {
            $DiskType = foreach ($DiskContainers in $NodeDiskContainerType) {
                [PSCustomObject] @{
                    'Container' = $DiskContainers.Name
                    'Disk Count' = $DiskContainers | Select-Object -ExpandProperty Count
                    }
                }
                if ($Healthcheck.Storage.DiskStatus) {
                    $DiskType | Where-Object { $_.'Container' -like 'broken' } | Set-Style -Style Critical -Property 'Disk Count'
                }
            $TableParams = @{
                Name = "Disk Container Type Summary - $($ClusterInfo.ClusterName)"
                List = $false
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $DiskType | Table @TableParams
        }
    }

    end {}

}