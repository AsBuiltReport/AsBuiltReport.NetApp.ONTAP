function Get-AbrOntapVserverVolumesQosGPAdaptive {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP vserver volumes qos group adaptive information from the Cluster Management Network
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
        Write-PScriboMessage "Collecting ONTAP Vserver volumes qos group adaptive information."
    }

    process {
        try {
            $QoSFilter = Get-NcQosAdaptivePolicyGroup -Controller $Array
            $OutObj = @()
            if ($QoSFilter) {
                foreach ($Item in $QoSFilter) {
                    try {
                        $inObj = [ordered] @{
                            'Policy Name' = $Item.PolicyGroup
                            'Peak Iops' = $Item.PeakIops
                            'Expected Iops' = $Item.ExpectedIops
                            'Min Iops' = $Item.AbsoluteMinIops
                            'Vserver' = $Item.Vserver
                        }
                        $OutObj += [pscustomobject]$inobj
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }

                $TableParams = @{
                    Name = "Volume Adaptive QoS Group - $($ClusterInfo.ClusterName)"
                    List = $false
                    ColumnWidths = 20, 24, 24, 12, 20
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
