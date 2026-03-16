function Get-AbrOntapCluster {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP cluster information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.6.12
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
        Write-PScriboMessage 'Collecting ONTAP cluster information.'
    }

    process {
        try {
            $ClusterInfo = Get-NcCluster -Controller $Array
            if ($ClusterInfo) {
                $OutObj = @()
                try {
                    $inObj = [ordered] @{
                        'Cluster Name' = $ClusterInfo.ClusterName
                        'Cluster UUID' = $ClusterInfo.ClusterUuid
                        'Cluster Serial' = $ClusterInfo.ClusterSerialNumber
                        'Cluster Controller' = $ClusterInfo.NcController
                        'Cluster Contact' = $ClusterInfo.ClusterContact ?? '--'
                        'Cluster Location' = $ClusterInfo.ClusterLocation ?? '--'
                        'Ontap Version' = (Get-NcSystemVersion -Controller $Array).value ?? 'Unknown'
                        'Number of Aggregates' = (Get-NcAggr -Controller $Array).count ?? 'Unknown'
                        'Number of Volumes' = (Get-NcVol -Controller $Array).count ?? 'Unknown'
                        'Overall System Health' = (Get-NcDiagnosisStatus -Controller $Array).Status?.ToUpper() ?? 'Unknown'
                    }
                    $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                } catch {
                    Write-PScriboMessage -IsWarning $_.Exception.Message
                }

                if ($Healthcheck.Cluster.Summary) {
                    $OutObj | Where-Object { $_.'Overall System Health' -like 'OK' } | Set-Style -Style OK -Property 'Overall System Health'
                    $OutObj | Where-Object { $_.'Overall System Health' -notlike 'OK' } | Set-Style -Style Critical -Property 'Overall System Health'
                }

                $TableParams = @{
                    Name = "Cluster Information - $($ClusterInfo.ClusterName)"
                    List = $true
                    ColumnWidths = 25, 75
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $OutObj | Table @TableParams
                if ($Healthcheck.Cluster.Summary -and ($OutObj | Where-Object { $_.'Overall System Health' -notlike 'OK' })) {
                    Paragraph 'Health Check:' -Bold -Underline
                    BlankLine
                    Paragraph {
                        Text 'Best Practice:' -Bold
                        Text 'The overall system health is not OK. It is recommended to investigate the issue further to ensure the cluster is functioning properly.'
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