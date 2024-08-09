function Get-AbrOntapVserverNamespaceStorage {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP vserver namespace information from the Cluster Management Network
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
        Write-PScriboMessage "Collecting ONTAP Vserver namespace information."
    }

    process {
        try {
            $VserverNamespace = Get-NcNvmeNamespace -VserverContext $Vserver -Controller $Arra
            $VserverObj = @()
            if ($VserverNamespace) {
                foreach ($Item in $VserverNamespace) {
                    try {
                        $namespacemap = Get-NcNvmeSubsystemMap -Vserver $Vserver -Controller $Array | Where-Object { $_.Path -eq $Item.Path }
                        $namespacepath = $Item.Path.split('/')
                        $namespace = $namespacepath[3]
                        $available = $Item.Size - $Item.SizeUsed
                        $used = ($Item.SizeUsed / $Item.Size) * 100
                        $inObj = [ordered] @{
                            'Namespace Name' = $namespace
                            'Parent Volume' = $Item.Volume
                            'Path' = $Item.Path
                            'Serial Number' = $Item.Uuid
                            'Subsystem Map' = Switch (($namespacemap).count) {
                                0 { "None" }
                                default { $namespacemap.Subsystem }
                            }
                            'Home Node ' = $Item.Node
                            'Capacity' = $Item.Size | ConvertTo-FormattedNumber -Type Datasize -ErrorAction SilentlyContinue
                            'Available' = $available | ConvertTo-FormattedNumber -Type Datasize -ErrorAction SilentlyContinue
                            'Used' = $used | ConvertTo-FormattedNumber -Type Percent -ErrorAction SilentlyContinue
                            'OS Type' = $Item.Ostype
                            'Is Mapped' = Switch ([string]::IsNullOrEmpty($Item.Subsystem)) {
                                $true { "No" }
                                $false { "Yes" }
                                default { $Item.Subsystem }
                            }
                            'ReadOnly' = ConvertTo-TextYN $Item.IsReadOnly
                            'Status' = Switch ($Item.State) {
                                'online' { 'Up' }
                                'offline' { 'Down' }
                                default { $Item.Online }
                            }
                        }
                        $VserverObj = [pscustomobject]$inobj

                        if ($Healthcheck.Vserver.Status) {
                            $VserverObj | Where-Object { $_.'Status' -like 'Down' } | Set-Style -Style Warning -Property 'Status'
                            $VserverObj | Where-Object { $_.'Used' -ge 90 } | Set-Style -Style Critical -Property 'Used'
                            $VserverObj | Where-Object { $_.'Is Mapped' -eq 'No' } | Set-Style -Style Warning -Property 'Is Mapped'
                        }

                        $TableParams = @{
                            Name = "Namespace - $($namespace)"
                            List = $true
                            ColumnWidths = 25, 75
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $VserverObj | Sort-Object -Property 'Namespace Name' | Table @TableParams
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning $_.Exception.Message
        }
    }

    end {}

}