function Get-AbrOntapClusterASUP {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP cluster autoSupport status from the Cluster Management Network
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
        Write-PScriboMessage "Collecting ONTAP AutoSupport information."
    }

    process {
        try {
            $AutoSupport = Get-NcAutoSupportConfig -Controller $Array -ErrorAction Continue
            if ($AutoSupport) {
                $Outobj = @()
                foreach ($NodesAUTO in $AutoSupport) {
                    try {
                        $Inobj = [ordered] @{
                            'Node Name' = $NodesAUTO.NodeName
                            'Protocol' = $NodesAUTO.Transport
                            'Enabled' = ConvertTo-TextYN $NodesAUTO.IsEnabled
                            'Last Time Stamp' = $NodesAUTO.LastTimestampDT
                            'Last Subject' = $NodesAUTO.LastSubject
                        }
                        $Outobj = [PSCustomObject]$Inobj

                        if ($Healthcheck.Cluster.AutoSupport) {
                            $Outobj | Where-Object { $_.'Enabled' -like 'No' } | Set-Style -Style Warning -Property 'Enabled'
                        }

                        $TableParams = @{
                            Name = "Cluster AutoSupport Status - $($NodesAUTO.NodeName)"
                            List = $true
                            ColumnWidths = 25, 75
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $Outobj | Table @TableParams
                        if ($Healthcheck.Cluster.AutoSupport -and ($Outobj | Where-Object { $_.'Enabled' -like 'No' })) {
                            Paragraph "Health Check:" -Bold -Underline
                            BlankLine
                            Paragraph {
                                Text "Best Practice:" -Bold
                                Text "AutoSupport is disabled on one or more nodes. It is recommended to enable AutoSupport to ensure proactive monitoring and issue resolution."
                            }
                            BlankLine
                        }
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning $_.Exception.Message
        }
    }

    end {}

}