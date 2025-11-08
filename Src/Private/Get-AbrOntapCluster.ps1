function Get-AbrOntapCluster {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP cluster information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.6.8
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
        Write-PScriboMessage "Collecting ONTAP cluster information."
    }

    process {
        try {
            $ClusterInfo = Get-NcCluster -Controller $Array
            if ($ClusterInfo) {
                $ClusterDiag = Get-NcDiagnosisStatus -Controller $Array
                $ClusterVersion = Get-NcSystemVersion -Controller $Array
                $ArrayAggr = Get-NcAggr -Controller $Array
                $ArrayVolumes = Get-NcVol -Controller $Array
                $ClusterSummary = [PSCustomObject] @{
                    'Cluster Name' = $ClusterInfo.ClusterName
                    'Cluster UUID' = $ClusterInfo.ClusterUuid
                    'Cluster Serial' = $ClusterInfo.ClusterSerialNumber
                    'Cluster Controller' = $ClusterInfo.NcController
                    'Cluster Contact' = ConvertTo-EmptyToFiller $ClusterInfo.ClusterContact
                    'Cluster Location' = ConvertTo-EmptyToFiller $ClusterInfo.ClusterLocation
                    'Ontap Version' = $ClusterVersion.value
                    'Number of Aggregates' = $ArrayAggr.count
                    'Number of Volumes' = $ArrayVolumes.count
                    'Overall System Health' = switch ([string]::IsNullOrEmpty($ClusterDiag.Status)) {
                        $true { '--' }
                        $false { $ClusterDiag.Status.ToUpper() }
                        default { 'Unknown' }
                    }
                }
                if ($Healthcheck.Cluster.Summary) {
                    $ClusterSummary | Where-Object { $_.'Overall System Health' -like 'OK' } | Set-Style -Style OK -Property 'Overall System Health'
                    $ClusterSummary | Where-Object { $_.'Overall System Health' -notlike 'OK' } | Set-Style -Style Critical -Property 'Overall System Health'
                }

                $TableParams = @{
                    Name = "Cluster Information - $($ClusterInfo.ClusterName)"
                    List = $true
                    ColumnWidths = 25, 75
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $ClusterSummary | Table @TableParams
                if ($Healthcheck.Cluster.Summary -and ($ClusterSummary | Where-Object { $_.'Overall System Health' -notlike 'OK' })) {
                    Paragraph "Health Check:" -Bold -Underline
                    BlankLine
                    Paragraph {
                        Text "Best Practice:" -Bold
                        Text "The overall system health is not OK. It is recommended to investigate the issue further to ensure the cluster is functioning properly."
                    }
                    BlankLine
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning $_.Exception.Message
        }
    }

    end {}

}