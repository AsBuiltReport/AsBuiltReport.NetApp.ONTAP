function Get-AbrOntapVserverNFSSummary {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP Vserver NFS information from the Cluster Management Network
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
        Write-PScriboMessage "Collecting ONTAP Vserver NFS information."
    }

    process {
        try {
            $VserverData = Get-NcNfsService -VserverContext $Vserver -Controller $Array
            $VserverObj = @()
            if ($VserverData) {
                foreach ($Item in $VserverData) {
                    try {
                        $inObj = [ordered] @{
                            'Nfs v3' = switch ($Item.IsNfsv3) {
                                'True' { 'Enabled' }
                                'False' { 'Disabled' }
                                default { $Item.IsNfsv3 }
                            }
                            'Nfs v4' = switch ($Item.IsNfsv4) {
                                'True' { 'Enabled' }
                                'False' { 'Disabled' }
                                default { $Item.IsNfsv4 }
                            }
                            'Nfs v41' = switch ($Item.IsNfsv41) {
                                'True' { 'Enabled' }
                                'False' { 'Disabled' }
                                default { $Item.IsNfsv41 }
                            }
                            'General Access' = ConvertTo-TextYN $Item.GeneralAccess

                        }
                        $VserverObj += [pscustomobject]$inobj
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }
                if ($Healthcheck.Vserver.NFS) {
                    $VserverObj | Where-Object { $_.'Nfs v3' -like 'Disabled' -and $_.'Nfs v4' -like 'Disabled' -and $_.'Nfs v41' -like 'Disabled' } | Set-Style -Style Warning
                }

                $TableParams = @{
                    Name = "NFS Service - $($ClusterInfo.ClusterName)"
                    List = $false
                    ColumnWidths = 25, 25, 25, 25
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $VserverObj | Table @TableParams
                if ($Healthcheck.Vserver.NFS -and ($VserverObj | Where-Object { $_.'Nfs v3' -like 'Disabled' -and $_.'Nfs v4' -like 'Disabled' -and $_.'Nfs v41' -like 'Disabled' })) {
                    Paragraph "Health Check:" -Bold -Underline
                    BlankLine
                    Paragraph {
                        Text "Best Practice:" -Bold
                        Text "Evaluate enabling NFS services to support client connectivity and file sharing."
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