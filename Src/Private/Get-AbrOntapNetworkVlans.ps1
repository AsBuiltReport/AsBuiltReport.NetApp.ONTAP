function Get-AbrOntapNetworkVlans {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP Interface VLAN information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.4.0
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
            $Node
    )

    begin {
        Write-PscriboMessage "Collecting ONTAP VLAN information."
    }

    process {
        $Vlan = Get-NcNetPortVlan -Node $Node
        $VlanObj = @()
        if ($Vlan) {
            foreach ($Item in $Vlan) {
                $inObj = [ordered] @{
                    'Interface Name' = $Item.InterfaceName
                    'Parent Interface' = $Item.ParentInterface
                    'Vlan ID' = $Item.VlanID
                }
                $VlanObj += [pscustomobject]$inobj
            }

            $TableParams = @{
                Name = "Network VLAN Information - $($Node)"
                List = $false
                ColumnWidths = 34, 33, 33
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $VlanObj | Table @TableParams
        }
    }

    end {}

}