function Get-AbrOntapVserverVolumesQosSetting {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP vserver volumes qos information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.6.7
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
        Write-PScriboMessage "Collecting ONTAP Vserver volumes qos information."
    }

    process {
        try {
            $VolumeFilter = Get-NcVol -VserverContext $Vserver -Controller $Array | Where-Object { $_.JunctionPath -ne '/' -and $_.Name -ne 'vol0' -and $_.VolumeStateAttributes.IsConstituent -ne "True" }
            $OutObj = @()
            if ($VolumeFilter) {
                foreach ($Item in $VolumeFilter) {
                    try {
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
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }

                $TableParams = @{
                    Name = "Volume QoS - $($Vserver)"
                    List = $false
                    ColumnWidths = 50, 25, 25
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