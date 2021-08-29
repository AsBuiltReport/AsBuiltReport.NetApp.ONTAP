function Get-AbrOntapVserverVolumesQos {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP vserver volumes qos information from the Cluster Management Network
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
        Write-PscriboMessage "Collecting ONTAP Vserver volumes qos information."
    }

    process {
        $VolumeFilter =  Get-NcVol | Where-Object {$_.JunctionPath -ne '/' -and $_.Name -ne 'vol0' -and $_.VolumeStateAttributes.IsConstituent -ne "True"}
        $OutObj = @()
        if ($VolumeFilter) {
            foreach ($Item in $VolumeFilter) {
                $VolQoS = Get-NcVol $Item.Name | Select-Object -ExpandProperty VolumeQosAttributes
                $inObj = [ordered] @{
                    'Volume' = $Item.Name
                    'Fixed Policy Name' = $VolQoS.PolicyGroupName
                    'Adaptive Policy Name' = $VolQoS.AdaptivePolicyGroupName
                    'Vserver' = $Item.Vserver
                }
                $OutObj += [pscustomobject]$inobj
            }

            $TableParams = @{
                Name = "Vserver Volume QoS Information - $($ClusterInfo.ClusterName)"
                List = $false
                ColumnWidths = 40, 20, 20, 20
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $OutObj | Table @TableParams
        }
    }

    end {}

}