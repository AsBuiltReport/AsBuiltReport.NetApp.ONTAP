function Get-AbrOntapDiskType {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP disk type information from the Cluster Management Network
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
        Write-PScriboMessage "Collecting ONTAP disk type per node information."
    }

    process {
        try {
            $NodeDiskContainerType = Get-NcDisk -Controller $Array | ForEach-Object { $_.DiskRaidInfo.ContainerType } | Group-Object
            if ($NodeDiskContainerType) {
                $DiskType = foreach ($DiskContainers in $NodeDiskContainerType) {
                    try {
                        [PSCustomObject] @{
                            'Container' = $DiskContainers.Name
                            'Disk Count' = $DiskContainers | Select-Object -ExpandProperty Count
                        }
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }
                if ($Healthcheck.Storage.DiskStatus) {
                    $DiskType | Where-Object { $_.'Container' -like 'broken' } | Set-Style -Style Critical -Property 'Disk Count'
                }
                $TableParams = @{
                    Name = "Disk Container Type - $($ClusterInfo.ClusterName)"
                    List = $false
                    ColumnWidths = 50, 50
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $DiskType | Table @TableParams
            }
            $Node = Get-NcNode | Where-Object { $_.IsNodeHealthy -eq "True" }
            if ($Node -and (Confirm-NcAggrSpareLow | Where-Object { $_.Value -eq "True" })) {
                $OutObj = foreach ($Item in $Node) {
                    try {
                        $DiskSpareLow = Confirm-NcAggrSpareLow -Node $Item.Node
                        [PSCustomObject] @{
                            'Node' = $Item.Node
                            'Aggregate Spare Low' = $DiskSpareLow.Value.ToString().Replace("True", "Yes").Replace("False", "No")
                        }
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }
                if ($Healthcheck.Storage.DiskStatus) {
                    $OutObj | Where-Object { $_.'Aggregate Spare Low' -like 'Yes' } | Set-Style -Style Critical -Property 'Node', 'Aggregate Spare Low'
                }
                $TableParams = @{
                    Name = "HealthCheck - Aggregate Disk Spare Low - $($ClusterInfo.ClusterName)"
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