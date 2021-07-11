function Get-AbrOntapNetworkVlans {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP Interface VLAN information from the Cluster Management Network
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
        Write-PscriboMessage "Collecting ONTAP VLAN information."
    }

    process {
        $global:Vlan = Get-NcNetPortVlan
        $VlanObj = @()
        if ($Vlan) {
            foreach ($Item in $Vlan) {
                $inObj = [ordered] @{
                    'InterfaceName' = $Item.InterfaceName
                    'ParentInterface' = $Item.ParentInterface
                    'VlanID' = $Item.VlanID
                    'Node' = $Item.Node
                }
                $VlanObj += [pscustomobject]$inobj
            }

            $TableParams = @{
                Name = "Network VLAN Information - $($ClusterInfo.ClusterName)"
                List = $false
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $VlanObj | Table @TableParams
        }
    }

    end {}

}