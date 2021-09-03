function Get-AbrOntapVserverIscsiSummary {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP Vserver ISCSI information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.3.0
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
        Write-PscriboMessage "Collecting ONTAP Vserver ISCSI information."
    }

    process {
        $VserverData = Get-NcIscsiService
        $VserverObj = @()
        if ($VserverData) {
            foreach ($Item in $VserverData) {
                $inObj = [ordered] @{
                    'Vserver' = $Item.Vserver
                    'IQN Name' = $Item.NodeName
                    'Alias Name' = $Item.AliasName
                    'Status' = Switch ($Item.IsAvailable) {
                        'True' { 'Up' }
                        'False' { 'Down' }
                    }
                }
                $VserverObj += [pscustomobject]$inobj
            }
            if ($Healthcheck.Vserver.Iscsi) {
                $VserverObj | Where-Object { $_.'Status' -like 'Down' } | Set-Style -Style Warning -Property 'Status'
            }

            $TableParams = @{
                Name = "Vserver ISCSI Service Information - $($ClusterInfo.ClusterName)"
                List = $false
                ColumnWidths = 15, 65, 12, 8
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $VserverObj | Table @TableParams
        }
    }

    end {}

}