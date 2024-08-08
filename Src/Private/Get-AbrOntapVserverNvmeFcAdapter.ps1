function Get-AbrOntapVserverNvmeFcAdapter {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP Vserver Nvme FC adapter information from the Cluster Management Network
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
        Write-PScriboMessage "Collecting ONTAP Vserver Nvme FC adapter information."
    }

    process {
        try {
            $VserverData = Get-NcNvmeInterface -VserverContext $Vserver -Controller $Array | Where-Object {$_.PhysicalProtocol -eq 'fibre_channel'} | Sort-Object -Property HomeNode
            $VserverObj = @()
            if ($VserverData) {
                foreach ($Item in $VserverData) {
                    try {
                        $inObj = [ordered] @{
                            'Node Name' = $Item.HomeNode
                            'Adapter' = $Item.HomePort
                            'Protocol' = $Item.PhysicalProtocol
                            'WWNN' = $Item.FcWwnn
                            'WWPN' = $Item.FcWwpn
                            'Status' = Switch ($Item.StatusAdmin) {
                                'up' { 'Up' }
                                'down' { 'Down' }
                                default { $Item.StatusAdmin }
                            }
                        }
                        $VserverObj += [pscustomobject]$inobj
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }
                if ($Healthcheck.Vserver.FCP) {
                    $VserverObj | Where-Object { $_.'Status' -like 'Down' } | Set-Style -Style Warning -Property 'Status'
                }

                $TableParams = @{
                    Name = "Nvme FC Physical Adapter - $($Vserver)"
                    List = $false
                    ColumnWidths = 25, 12, 15, 18, 18, 12

                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $VserverObj | Table @TableParams
            }
        } catch {
            Write-PScriboMessage -IsWarning $_.Exception.Message
        }
    }

    end {}

}