function Get-AbrOntapClusterHA {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP cluster HA information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.6.6
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
        Write-PscriboMessage "Collecting ONTAP cluster high availability information."
    }

    process {
        try {
            $NodeSum = Get-NcNode -Controller $Array | Where-Object { $null -ne $_.NodeModel }
            if ($NodeSum) {
                $NodeSummary = foreach ($Nodes in $NodeSum) {
                    try {
                        $ClusterHa = Get-NcClusterHa -Node $Nodes.Node -Controller $Array
                        [PSCustomObject] @{
                            'Name' = $Nodes.Node
                            'Partner' = ConvertTo-EmptyToFiller $ClusterHa.Partner
                            'TakeOver Possible' = ConvertTo-TextYN $ClusterHa.TakeoverPossible
                            'TakeOver State' = ConvertTo-EmptyToFiller $ClusterHa.TakeoverState
                            'HA Mode' = $ClusterHa.CurrentMode.ToUpper()
                            'HA State' = $ClusterHa.State.ToUpper()
                        }
                    }
                    catch {
                        Write-PscriboMessage -IsWarning $_.Exception.Message
                    }
                }
                if ($Healthcheck.Cluster.HA) {
                    $NodeSummary | Where-Object { $_.'TakeOver State' -like 'in_takeover' } | Set-Style -Style Warning -Property 'TakeOver State'
                    $NodeSummary | Where-Object { $_.'HA State' -notlike 'connected' } | Set-Style -Style Warning -Property 'HA State'
                }

                $TableParams = @{
                    Name = "Cluster HA Status - $($ClusterInfo.ClusterName)"
                    List = $false
                    ColumnWidths = 20, 20, 11, 19, 10, 20
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $NodeSummary | Table @TableParams
            }
        }
        catch {
            Write-PscriboMessage -IsWarning $_.Exception.Message
        }
    }

    end {}

}