function Get-AbrOntapVserverNonMappedNamespace {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP NVMW Non Mapped amespace information from the Cluster Management Network
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
        Write-PScriboMessage "Collecting ONTAP NVME Non Mapped Namespace information."
    }

    process {
        try {
            $NamespaceFilter = Get-NcNvmeNamespace -VserverContext $Vserver -Controller $Array | Where-Object { -Not $_.Subsystem }
            $OutObj = @()
            if ($NamespaceFilter) {
                foreach ($Item in $NamespaceFilter) {
                    try {
                        $namespacename = (($Item.Path).split('/'))[3]
                        $inObj = [ordered] @{
                            'Volume Name' = $Item.Volume
                            'Lun Name' = $namespacename
                            'Type' = $Item.Ostype
                            'Mapped' = "No"
                            'State' = $Item.State
                        }
                        $OutObj += [pscustomobject]$inobj
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }
                if ($Healthcheck.Vserver.Status) {
                    $OutObj | Set-Style -Style Warning
                }

                $TableParams = @{
                    Name = "HealthCheck - Non-Mapped Namespace - $($Vserver)"
                    List = $false
                    ColumnWidths = 30, 30, 10, 10, 20
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $OutObj | Table @TableParams
            }
        } catch {
            Write-PScriboMessage -IsWarning $_.Exception.Message
        }
    }

    end {}

}