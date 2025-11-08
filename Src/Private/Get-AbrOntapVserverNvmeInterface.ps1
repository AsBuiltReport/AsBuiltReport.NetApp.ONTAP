function Get-AbrOntapVserverNvmeInterface {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP Vserver NVME interface information from the Cluster Management Network
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
        Write-PScriboMessage "Collecting ONTAP Vserver NVME interface information."
    }

    process {
        try {
            $VserverData = Get-NcNvmeInterface -VserverContext $Vserver -Controller $Array | Sort-Object -Property TransportProtocols
            $VserverObj = @()
            if ($VserverData) {
                foreach ($Item in $VserverData) {
                    try {
                        $inObj = [ordered] @{
                            'Interface Name' = $Item.Lif
                            'Transport Address' = $Item.TransportAddress
                            'Transport Protocols' = $Item.TransportProtocols
                            'Status' = switch ($Item.StatusAdmin) {
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
                if ($Healthcheck.Vserver.Nvme) {
                    $VserverObj | Where-Object { $_.'Status' -like 'Down' } | Set-Style -Style Warning -Property 'Status'
                }

                $TableParams = @{
                    Name = "NVME Interface - $($Vserver)"
                    List = $false
                    ColumnWidths = 40, 36, 12, 12
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $VserverObj | Table @TableParams
                if ($Healthcheck.Vserver.Nvme -and ($VserverObj | Where-Object { $_.'Status' -like 'Down' })) {
                    Paragraph "Health Check:" -Bold -Underline
                    BlankLine
                    Paragraph {
                        Text "Best Practice:" -Bold
                        Text "Ensure all NVME interfaces are in 'Up' status to maintain optimal connectivity and performance."
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