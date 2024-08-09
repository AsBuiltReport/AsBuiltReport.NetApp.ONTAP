function Get-AbrOntapVserverSubsystem {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP vserver subsystem information from the Cluster Management Network
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
        Write-PScriboMessage "Collecting ONTAP Vserver Subsystem information."
    }

    process {
        try {
            $VserverSubsystem = Get-NcNvmeSubsystem -VserverContext $Vserver -Controller $Array
            $VserverObj = @()
            if ($VserverSubsystem) {
                foreach ($Item in $VserverSubsystem) {
                    try {
                        $namespacemap = Get-NcNvmeSubsystemMap -Controller $Array | Where-Object { $_.Subsystem -eq $Item.Subsystem } | Select-Object -ExpandProperty Path
                        $MappedNamespace = @()
                        foreach ($namespace in $namespacemap) {
                            try {
                                $namespacename = $namespace.split('/')
                                $MappedNamespace += $namespacename[3]
                            } catch {
                                Write-PScriboMessage -IsWarning $_.Exception.Message
                            }
                        }
                        $inObj = [ordered] @{
                            'Subsystem Name' = $Item.Subsystem
                            'Type' = $Item.Ostype
                            'Target NQN' = $Item.TargetNqn
                            'Host NQN' = $Item.Hosts.Nqn
                            'Mapped Namespace' = Switch (($MappedNamespace).count) {
                                0 { "None" }
                                default { $MappedNamespace }
                            }
                        }
                        $VserverObj = [pscustomobject]$inobj
                        if ($Healthcheck.Vserver.Status) {
                            $VserverObj | Where-Object { ($_.'Mapped Namespace').count -eq 0 } | Set-Style -Style Warning -Property 'Mapped Namespace'
                        }

                        $TableParams = @{
                            Name = "Subsystem - $($Item.Subsystem)"
                            List = $true
                            ColumnWidths = 25, 75
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $VserverObj | Table @TableParams
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