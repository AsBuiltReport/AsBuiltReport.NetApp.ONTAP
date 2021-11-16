function Get-AbrOntapSecuritySnapLockAggr {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP Security Aggregate Snaplock Type information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.5.0
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
        Write-PscriboMessage "Collecting ONTAP Security Aggregate Snaplock Type information."
    }

    process {
        $Data =  Get-NcAggr -Controller $Array | Where-Object {$_.AggrRaidAttributes.HasLocalRoot -ne 'True'}
        $OutObj = @()
        if ($Data) {
            foreach ($Item in $Data) {
                $SnapLockType = Get-NcAggr $Item.Name -Controller $Array | Select-Object -ExpandProperty AggrSnaplockAttributes
                $inObj = [ordered] @{
                    'Aggregate Name' = $Item.Name
                    'Snaplock Type' = $TextInfo.ToTitleCase($SnapLockType.SnaplockType)
                }
                $OutObj += [pscustomobject]$inobj
            }

            $TableParams = @{
                Name = "Aggregate Snaplock Type Information - $($ClusterInfo.ClusterName)"
                List = $false
                ColumnWidths = 40, 60
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $OutObj | Table @TableParams
        }
    }

    end {}

}