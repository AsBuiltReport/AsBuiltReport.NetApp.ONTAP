function Get-AbrOntapVserverCIFSSummary {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP Vserver CIFS information from the Cluster Management Network
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
                                'Status' = $SVM.Status.ToString().ToUpper()
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