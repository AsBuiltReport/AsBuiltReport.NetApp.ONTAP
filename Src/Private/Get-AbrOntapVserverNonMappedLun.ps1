function Get-AbrOntapVserverNonMappedLun {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP ISCSI/FCP Non Mapped Lun information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.4.0
        Author:         Jonathan Colon
        Twitter:        @jcolonfzenpr
        Github:         rebelinux
    .EXAMPLE

    .LINK

    #>
    [CmdletBinding()]
    param (
    )

    begin {
        Write-PscriboMessage "Collecting ONTAP ISCSI/FCP Non Mapped Lun information."
    }

    process {
        $LunFilter = Get-NcLun | Where-Object {$_.Mapped -ne "True"}
        $OutObj = @()
        if ($LunFilter) {
            foreach ($Item in $LunFilter) {
                $lunname = (($Item.Path).split('/'))[3]
                $inObj = [ordered] @{
                    'Volume Name' = $Item.Volume
                    'Lun Name' = $lunname
                    'Online' = ConvertTo-TextYN $Item.Online
                    'Mapped' = ConvertTo-TextYN $Item.Mapped
                    'Lun Format' = $Item.Protocol
                    'Vserver' = $Item.Vserver
                }
                $OutObj += [pscustomobject]$inobj
            }
            if ($Healthcheck.Vserver.Status) {
                $OutObj | Set-Style -Style Warning -Property 'Volume Name','Lun Name','Online','Mapped','Lun Format','Vserver'
            }

            $TableParams = @{
                Name = "HealthCheck - Non-Mapped Lun - $($ClusterInfo.ClusterName)"
                List = $false
                ColumnWidths = 25, 25, 10, 10, 15, 15
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $OutObj | Table @TableParams
        }
    }

    end {}

}