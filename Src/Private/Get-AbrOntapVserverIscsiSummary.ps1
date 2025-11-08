function Get-AbrOntapVserverIscsiSummary {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP Vserver ISCSI information from the Cluster Management Network
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
        Write-PScriboMessage "Collecting ONTAP Vserver ISCSI information."
    }

    process {
        try {
            $VserverData = Get-NcIscsiService -VserverContext $Vserver -Controller $Array
            $VserverObj = @()
            if ($VserverData) {
                foreach ($Item in $VserverData) {
                    try {
                        $inObj = [ordered] @{
                            'IQN Name' = $Item.NodeName
                            'Alias Name' = $Item.AliasName
                            'Tcp Window Size' = $Item.TcpWindowSize
                            'Max Cmds Per Session' = $Item.MaxCmdsPerSession
                            'Max Conn Per Session' = $Item.MaxConnPerSession
                            'Login Timeout' = $Item.LoginTimeout
                            'Status' = switch ($Item.IsAvailable) {
                                'True' { 'Up' }
                                'False' { 'Down' }
                                default { $Item.IsAvailable }
                            }
                        }
                        $VserverObj += [pscustomobject]$inobj
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }
                if ($Healthcheck.Vserver.Iscsi) {
                    $VserverObj | Where-Object { $_.'Status' -like 'Down' } | Set-Style -Style Warning -Property 'Status'
                }

                $TableParams = @{
                    Name = "ISCSI Service - $($Vserver)"
                    List = $true
                    ColumnWidths = 30, 70
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $VserverObj | Table @TableParams
                if ($Healthcheck.Vserver.Iscsi -and ($VserverObj | Where-Object { $_.'Status' -like 'Down' })) {
                    Paragraph "Health Check:" -Bold -Underline
                    BlankLine
                    Paragraph {
                        Text "Best Practice:" -Bold
                        Text "Ensure that all ISCSI services are operational to maintain optimal storage connectivity."
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