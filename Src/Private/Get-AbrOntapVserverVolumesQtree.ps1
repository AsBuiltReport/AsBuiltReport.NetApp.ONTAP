function Get-AbrOntapVserverVolumesQtree {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP vserver volumes qtree information from the Cluster Management Network
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
        Write-PScriboMessage "Collecting ONTAP Vserver volumes qtree information."
    }

    process {
        try {
            $VserverQtree = Get-NcQtree -VserverContext $Vserver -Controller $Array | Where-Object { $NULL -ne $_.Qtree }
            $VserverObj = @()
            if ($VserverQtree) {
                foreach ($Item in $VserverQtree) {
                    try {
                        $inObj = [ordered] @{
                            'Qtree' = $Item.Qtree
                            'Volume' = $Item.Volume
                            'Status' = $Item.Status
                            'Security Style' = $Item.SecurityStyle
                            'Export Policy' = $Item.ExportPolicy
                        }
                        $VserverObj += [pscustomobject]$inobj
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }
                if ($Healthcheck.Vserver.Status) {
                    $VserverObj | Where-Object { $_.'Status' -notlike 'normal' } | Set-Style -Style Warning -Property 'Status'
                }

                $TableParams = @{
                    Name = "Volume Qtree - $($Vserver)"
                    List = $false
                    ColumnWidths = 27, 28, 15, 15, 15
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $VserverObj | Table @TableParams
                if ($Healthcheck.Vserver.Status -and ($VserverObj | Where-Object { $_.'Status' -notlike 'normal' })) {
                    Paragraph "Health Check:" -Bold -Underline
                    BlankLine
                    Paragraph {
                        Text "Best Practice:" -Bold
                        Text "Ensure all qtrees are in 'normal' status to maintain data integrity and accessibility."
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