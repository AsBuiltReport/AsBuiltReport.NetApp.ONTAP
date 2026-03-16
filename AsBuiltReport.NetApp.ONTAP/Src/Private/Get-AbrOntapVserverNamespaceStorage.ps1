function Get-AbrOntapVserverNamespaceStorage {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP vserver namespace information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.6.12
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
        Write-PScriboMessage 'Collecting ONTAP Vserver namespace information.'
    }

    process {
        try {
            $VserverNamespace = Get-NcNvmeNamespace -VserverContext $Vserver -Controller $Arra
            $VserverObj = @()
            if ($VserverNamespace) {
                foreach ($Item in $VserverNamespace) {
                    try {
                        $namespacemap = Get-NcNvmeSubsystemMap -Vserver $Vserver -Controller $Array | Where-Object { $_.Path -eq $Item.Path }
                        $namespace = $Item.Path.split('/')[3]
                        $inObj = [ordered] @{
                            'Namespace Name' = $namespace
                            'Parent Volume' = $Item.Volume
                            'Path' = $Item.Path
                            'Serial Number' = $Item.Uuid
                            'Subsystem Map' = ($namespacemap).count -eq 0 ? 'None': $namespacemap.Subsystem
                            'Home Node ' = $Item.Node
                            'Capacity' = ($Item.Size | ConvertTo-FormattedNumber -ErrorAction SilentlyContinue -NumberFormatString 0.0 -Type Datasize) ?? '--'
                            'Available' = (($Item.Size - $Item.SizeUsed) | ConvertTo-FormattedNumber -ErrorAction SilentlyContinue -NumberFormatString 0.0 -Type Datasize) ?? '--'
                            'Used' = ((($Item.SizeUsed / $Item.Size) * 100) | ConvertTo-FormattedNumber -ErrorAction SilentlyContinue -Type Percent) ?? '--'
                            'OS Type' = $Item.Ostype
                            'Is Mapped' = switch ([string]::IsNullOrEmpty($Item.Subsystem)) {
                                $true { 'No' }
                                $false { 'Yes' }
                                default { $Item.Subsystem }
                            }
                            'ReadOnly' = $Item.IsReadOnly
                            'Status' = switch ($Item.State) {
                                'online' { 'Up' }
                                'offline' { 'Down' }
                                default { $Item.Online }
                            }
                        }
                        $VserverObj = [pscustomobject](ConvertTo-HashToYN $inObj)

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
                        if ($Healthcheck.Vserver.Status -and ($VserverObj | Where-Object { $_.'Status' -like 'Down' })) {
                            Paragraph 'Health Check:' -Bold -Underline
                            BlankLine
                            Paragraph {
                                Text 'Best Practice:' -Bold
                                Text 'Ensure that all namespaces are operational to maintain optimal storage connectivity.'
                            }
                            BlankLine
                        }
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