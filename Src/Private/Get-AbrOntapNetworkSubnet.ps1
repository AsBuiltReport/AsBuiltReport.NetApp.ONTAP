function Get-AbrOntapNetworkSubnet {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP Network Subnet information from the Cluster Management Network
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
        Write-PscriboMessage "Collecting ONTAP Subnets information."
    }

    process {
        $Subnet = Get-NcNetSubnet
        $SubnetObj = @()
        if ($Subnet) {
            foreach ($Item in $Subnet) {
                $inObj = [ordered] @{
                    'Name' = $Item.Name
                    'Subnet' = $Item.Subnet
                    'Gateway' = $Item.Gateway
                    'Total IP' = $Item.Total
                    'Used IP' = $Item.Used
                    'Ip Ranges' = $Item.IpRanges
                }
                $SubnetObj += [pscustomobject]$inobj
            }

            $TableParams = @{
                Name = "Network Subnet Information - $($ClusterInfo.ClusterName)"
                List = $false
                ColumnWidths = 20, 20, 20, 10, 10, 20
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $SubnetObj | Table @TableParams
        }
    }

    end {}

}