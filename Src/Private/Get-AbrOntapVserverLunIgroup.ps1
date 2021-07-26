function Get-AbrOntapVserverLunIgroup {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP vserver igroup information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.1.0
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
        Write-PscriboMessage "Collecting ONTAP Vserver Igroup information."
    }

    process {
        $VserverIgroup = Get-NcIgroup
        $VserverObj = @()
        if ($VserverIgroup) {
            foreach ($Item in $VserverIgroup) {
                $lunmap = get-nclunmap | Where-Object { $_.InitiatorGroup -eq $Item.Name} | Select-Object -ExpandProperty Path
                $MappedLun = @()
                foreach ($lun in $lunmap) {
                    $lunname = $lun.split('/')
                    $MappedLun += $lunname[3]
                }
                $inObj = [ordered] @{
                    'Igroup Name' = $Item.Name
                    'Type' = $Item.Type
                    'Protocol' = $Item.Protocol
                    'Vserver' = $Item.Vserver
                    'Initiators' = $Item.Initiators.InitiatorName
                    'Mapped Lun' = $MappedLun
                }
                $VserverObj += [pscustomobject]$inobj
            }

            $TableParams = @{
                Name = "Vserver Igroup Information - $($ClusterInfo.ClusterName)"
                List = $true
                ColumnWidths = 25, 75
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $VserverObj | Table @TableParams
        }
    }

    end {}

}