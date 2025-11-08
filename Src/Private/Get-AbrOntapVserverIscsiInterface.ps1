function Get-AbrOntapVserverIscsiInterface {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP Vserver ISCSI interface information from the Cluster Management Network
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
        Write-PScriboMessage "Collecting ONTAP Vserver ISCSI interface information."
    }

    process {
        try {
            $VserverData = Get-NcIscsiInterface -VserverContext $Vserver -Controller $Array
            $VserverObj = @()
            if ($VserverData) {
                foreach ($Item in $VserverData) {
                    try {
                        $inObj = [ordered] @{
                            'Interface Name' = $Item.InterfaceName
                            'IP Address' = $Item.IpAddress
                            'Port' = $Item.IpPort
                            'Status' = switch ($Item.IsInterfaceEnabled) {
                                'True' { 'Up' }
                                'False' { 'Down' }
                                default { $Item.IsInterfaceEnabled }
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
                    Name = "ISCSI Interface - $($Vserver)"
                    List = $false
                    ColumnWidths = 40, 30, 15, 15
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
                        Text "Ensure that all ISCSI interfaces are operational to maintain optimal storage connectivity."
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