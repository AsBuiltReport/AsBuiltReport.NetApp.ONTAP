function Get-AbrOntapVserverVolumesQos {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP vserver volumes qos information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.5.0
        Author:         Jonathan Colon
        Twitter:        @jcolonfzenpr
        Github:         rebelinux
    .EXAMPLE

    .LINK

    #>
    param (
        [Parameter (
            Position = 0,
            Mandatory)]
            [string]
            $Vserver
    )

    begin {
        Write-PscriboMessage "Collecting ONTAP Vserver volumes qos information."
    }

    process {
        $VolumeFilter = Get-NcVol -VserverContext $Vserver -Controller $Array | Where-Object {$_.JunctionPath -ne '/' -and $_.Name -ne 'vol0' -and $_.VolumeStateAttributes.IsConstituent -ne "True"}
        $OutObj = @()
        if ($VolumeFilter) {
            foreach ($Item in $VolumeFilter) {
                $VolQoS = Get-NcVol $Item.Name -Controller $Array | Select-Object -ExpandProperty VolumeQosAttributes
                $inObj = [ordered] @{
                    'Volume' = $Item.Name
                    'Fixed Policy Name' = Switch ($VolQoS.PolicyGroupName) {
                        $Null { 'None' }
                        default { $VolQoS.PolicyGroupName }
                    }
                    'Adaptive Policy Name' = Switch ($VolQoS.AdaptivePolicyGroupName) {
                        $Null { 'None' }
                        default { $VolQoS.AdaptivePolicyGroupName }
                    }
                }
                $OutObj += [pscustomobject]$inobj
            }

            $TableParams = @{
                Name = "Vserver Volume QoS Information - $($Vserver)"
                List = $false
                ColumnWidths = 50, 25, 25
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $OutObj | Table @TableParams
        }
    }

    end {}

}