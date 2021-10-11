function Get-AbrOntapVserverIscsiSummary {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP Vserver ISCSI information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.4.0
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
        Write-PscriboMessage "Collecting ONTAP Vserver ISCSI information."
    }

    process {
        $VserverData = Get-NcIscsiService -VserverContext $Vserver
        $VserverObj = @()
        if ($VserverData) {
            foreach ($Item in $VserverData) {
                $inObj = [ordered] @{
                    'IQN Name' = $Item.NodeName
                    'Alias Name' = $Item.AliasName
                    'Tcp Window Size' = $Item.TcpWindowSize
                    'Max Cmds Per Session' = $Item.MaxCmdsPerSession
                    'Max Conn Per Session' = $Item.MaxConnPerSession
                    'Login Timeout' = $Item.LoginTimeout
                    'Status' = Switch ($Item.IsAvailable) {
                        'True' { 'Up' }
                        'False' { 'Down' }
                        default {$Item.IsAvailable}
                    }
                }
                $VserverObj += [pscustomobject]$inobj
            }
            if ($Healthcheck.Vserver.Iscsi) {
                $VserverObj | Where-Object { $_.'Status' -like 'Down' } | Set-Style -Style Warning -Property 'Status'
            }

            $TableParams = @{
                Name = "Vserver ISCSI Service Information - $($Vserver)"
                List = $true
                ColumnWidths = 40, 60
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $VserverObj | Table @TableParams
        }
    }

    end {}

}