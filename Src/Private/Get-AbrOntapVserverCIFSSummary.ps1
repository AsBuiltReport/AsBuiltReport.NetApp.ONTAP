function Get-AbrOntapVserverCIFSSummary {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP Vserver CIFS information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.6.8
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
        Write-PScriboMessage "Collecting ONTAP Vserver CIFS information."
    }

    process {
        try {
            $VserverData = Get-NcVserver -VserverContext $Vserver -Controller $Array | Where-Object { $_.VserverType -eq 'data' -and $_.AllowedProtocols -eq 'cifs' -and $_.State -eq 'running' }
            $VserverObj = @()
            if ($VserverData) {
                foreach ($Item in $VserverData) {
                    $CIFSSVM = Get-NcCifsServerStatus -VserverName $Item.Vserver -Controller $Array
                    foreach ($SVM in $CIFSSVM) {
                        try {
                            $inObj = [ordered] @{
                                'Node Name' = $SVM.NodeName
                                'Cifs Domain Name' = $SVM.CifsDomainName
                                'Cifs NetBios Name' = $SVM.CifsNetbiosName
                                'Cifs Domain IP' = $SVM.CifsDomainIpAddr
                                'AD Server Site' = $SVM.CifsServerSite
                                'Cifs Server Status' = $SVM.CifsServerStatus
                                'Status Details' = $SVM.StatusDetails
                                'Status' = $SVM.Status.ToString()
                            }
                            $VserverObj = [pscustomobject]$inobj

                            if ($Healthcheck.Vserver.CIFS) {
                                $VserverObj | Where-Object { $_.'Cifs Server Status' -notlike 'Running' } | Set-Style -Style Warning -Property 'Cifs Server Status'
                                $VserverObj | Where-Object { $_.'Status' -like 'down' } | Set-Style -Style Critical -Property 'Status'
                            }

                            $TableParams = @{
                                Name = "CIFS Service - $($SVM.NodeName)"
                                List = $true
                                ColumnWidths = 25, 75
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $VserverObj | Table @TableParams
                            if ($Healthcheck.Vserver.CIFS -and ($VserverObj | Where-Object { $_.'Status' -like 'down' })) {
                                Paragraph "Health Check:" -Bold -Underline
                                BlankLine
                                Paragraph {
                                    Text "Best Practice:" -Bold
                                    Text "Ensure that the CIFS service is running on all nodes to maintain file sharing capabilities."
                                }
                                BlankLine
                            }
                        } catch {
                            Write-PScriboMessage -IsWarning $_.Exception.Message
                        }
                    }
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning $_.Exception.Message
        }
    }

    end {}

}