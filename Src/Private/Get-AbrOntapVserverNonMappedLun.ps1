function Get-AbrOntapVserverNonMappedLun {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP ISCSI/FCP Non Mapped Lun information from the Cluster Management Network
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
        Write-PScriboMessage "Collecting ONTAP ISCSI/FCP Non Mapped Lun information."
    }

    process {
        try {
            $LunFilter = Get-NcLun -VserverContext $Vserver -Controller $Array | Where-Object { $_.Mapped -ne "True" }
            $OutObj = @()
            if ($LunFilter) {
                foreach ($Item in $LunFilter) {
                    try {
                        $lunname = (($Item.Path).split('/'))[3]
                        $inObj = [ordered] @{
                            'Volume Name' = $Item.Volume
                            'Lun Name' = $lunname
                            'Online' = ConvertTo-TextYN $Item.Online
                            'Mapped' = ConvertTo-TextYN $Item.Mapped
                            'Lun Format' = $Item.Protocol
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
                    Name = "HealthCheck - Non-Mapped Lun - $($Vserver)"
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