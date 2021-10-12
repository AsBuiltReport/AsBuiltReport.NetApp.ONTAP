function Get-AbrOntapClusterASUP {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP cluster autoSupport status from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.5.0
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
        Write-PscriboMessage "Collecting ONTAP AutoSupport information."
    }

    process {
        $AutoSupport = Get-NcAutoSupportConfig -Controller $Array
        if ($AutoSupport) {
            $AutoSupportSummary = foreach ($NodesAUTO in $AutoSupport) {
                [PSCustomObject] @{
                    'Node Name' = $NodesAUTO.NodeName
                    'Protocol' = $NodesAUTO.Transport
                    'Enabled' = ConvertTo-TextYN $NodesAUTO.IsEnabled
                    'Last Time Stamp' = $NodesAUTO.LastTimestampDT
                    'Last Subject' = $NodesAUTO.LastSubject
                }
            }
            if ($Healthcheck.Cluster.AutoSupport) {
                $AutoSupportSummary | Where-Object { $_.'Enabled' -like 'No' } | Set-Style -Style Warning -Property 'Enabled'
            }

            $TableParams = @{
                Name = "Cluster AutoSupport Status - $($ClusterInfo.ClusterName)"
                List = $true
                ColumnWidths = 25, 75
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $AutoSupportSummary | Table @TableParams
        }
    }

    end {}

}