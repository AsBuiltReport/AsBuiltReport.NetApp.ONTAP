function Get-AbrOntapNetworkFailoverGroup {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP Failover Group information from the Cluster Management Network
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
        Write-PscriboMessage "Collecting ONTAP Failover Group information."
    }

    process {
        $FG = Get-NcNetFailoverGroup
        $FGObj = @()
        if ($FG) {
            foreach ($Item in $FG) {
                $inObj = [ordered] @{
                    'Name' = $Item.FailoverGroup
                    'Vserver' = $Item.Vserver
                    'Target' = $Item.Target
                }
                $FGObj += [pscustomobject]$inobj
            }

            $TableParams = @{
                Name = "Network Failover Group Information - $($ClusterInfo.ClusterName)"
                List = $false
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $FGObj | Table @TableParams
        }
    }

    end {}

}