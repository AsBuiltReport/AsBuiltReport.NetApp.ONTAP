function Get-AbrOntapSecuritySnapLockAggr {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP Security Aggregate Snaplock Type information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.6.7
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
        Write-PScriboMessage "Collecting ONTAP Security Aggregate Snaplock Type information."
    }

    process {
        try {
            $Data = Get-NcAggr -Controller $Array | Where-Object { $_.AggrRaidAttributes.HasLocalRoot -ne 'True' }
            $OutObj = @()
            if ($Data) {
                foreach ($Item in $Data) {
                    try {
                        $SnapLockType = Get-NcAggr $Item.Name -Controller $Array | Select-Object -ExpandProperty AggrSnaplockAttributes
                        $inObj = [ordered] @{
                            'Aggregate Name' = $Item.Name
                            'Snaplock Type' = $TextInfo.ToTitleCase($SnapLockType.SnaplockType)
                        }
                        $OutObj += [pscustomobject]$inobj
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }

                $TableParams = @{
                    Name = "Aggregate Snaplock Type - $($ClusterInfo.ClusterName)"
                    List = $false
                    ColumnWidths = 40, 60
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