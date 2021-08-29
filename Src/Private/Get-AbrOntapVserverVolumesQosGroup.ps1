function Get-AbrOntapVserverVolumesQosGroup {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP vserver volumes qos group information from the Cluster Management Network
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
        Write-PscriboMessage "Collecting ONTAP Vserver volumes qos group information."
    }

    process {
        $QoSFilter = Get-NcQosPolicyGroup | Where-Object {$_.PolicyGroupClass -eq "user_defined"}
        $OutObj = @()
        if ($QoSFilter) {
            foreach ($Item in $QoSFilter) {
                $VolQoS = Get-NcVol $Item.Name | Select-Object -ExpandProperty VolumeQosAttributes
                $inObj = [ordered] @{
                    'Policy Name' = $Item.PolicyGroup
                    'Max Throughput' = $Item.MaxThroughput
                    'Min Throughput' = $Item.MinThroughput
                    'Is Shared' = Switch ($Item.IsShared) {
                        'True' { 'Yes' }
                        'False' { 'No' }
                    }
                    'Vserver' = $Item.Vserver
                }
                $OutObj += [pscustomobject]$inobj
            }

            $TableParams = @{
                Name = "Vserver Volume Fixed QoS Group Information - $($ClusterInfo.ClusterName)"
                List = $false
                ColumnWidths = 20, 24, 24, 12, 20
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $OutObj | Table @TableParams
        }
        $QoSFilter = Get-NcQosAdaptivePolicyGroup
        $OutObj = @()
        if ($QoSFilter) {
            foreach ($Item in $QoSFilter) {
                $VolQoS = Get-NcVol $Item.Name | Select-Object -ExpandProperty VolumeQosAttributes
                $inObj = [ordered] @{
                    'Policy Name' = $Item.PolicyGroup
                    'Peak Iops' = $Item.PeakIops
                    'Expected Iops' = $Item.ExpectedIops
                    'Min Iops' = $Item.AbsoluteMinIops
                    'Vserver' = $Item.Vserver
                }
                $OutObj += [pscustomobject]$inobj
            }

            $TableParams = @{
                Name = "Vserver Volume Adaptive QoS Group Information - $($ClusterInfo.ClusterName)"
                List = $false
                ColumnWidths = 20, 24, 24, 12, 20
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $OutObj | Table @TableParams
        }
    }

    end {}

}