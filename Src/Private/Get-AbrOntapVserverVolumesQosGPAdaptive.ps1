function Get-AbrOntapVserverVolumesQosGPAdaptive {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP vserver volumes qos group adaptive information from the Cluster Management Network
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
        Write-PscriboMessage "Collecting ONTAP Vserver volumes qos group adaptive information."
    }

    process {
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
                Name = "Volume Adaptive QoS Group Information - $($ClusterInfo.ClusterName)"
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