function Get-AbrOntapVserverVolumesQosGPFixed {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP vserver volumes qos group fixed information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.3.0
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
        Write-PscriboMessage "Collecting ONTAP Vserver volumes qos group fixed information."
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
                Name = "Volume Fixed QoS Group Information - $($ClusterInfo.ClusterName)"
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