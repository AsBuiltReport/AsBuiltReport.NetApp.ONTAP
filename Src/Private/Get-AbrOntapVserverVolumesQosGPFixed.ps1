function Get-AbrOntapVserverVolumesQosGPFixed {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP vserver volumes qos group fixed information from the Cluster Management Network
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
        Write-PScriboMessage "Collecting ONTAP Vserver volumes qos group fixed information."
    }

    process {
        try {
            $QoSFilter = Get-NcQosPolicyGroup -Controller $Array | Where-Object { $_.PolicyGroupClass -eq "user_defined" }
            $OutObj = @()
            if ($QoSFilter) {
                foreach ($Item in $QoSFilter) {
                    try {
                        $inObj = [ordered] @{
                            'Policy Name' = $Item.PolicyGroup
                            'Max Throughput' = $Item.MaxThroughput
                            'Min Throughput' = $Item.MinThroughput
                            'Is Shared' = ConvertTo-TextYN $Item.IsShared
                            'Vserver' = $Item.Vserver
                        }
                        $OutObj += [pscustomobject]$inobj
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }

                $TableParams = @{
                    Name = "Volume Fixed QoS Group - $($ClusterInfo.ClusterName)"
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
