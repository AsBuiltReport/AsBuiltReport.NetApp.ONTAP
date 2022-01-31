function Get-AbrOntapNetworkVlan {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP Interface VLAN information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.6.3
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
        try {
            $Vlan = Get-NcNetPortVlan -Node $Node -Controller $Array
            $VlanObj = @()
            if ($Vlan) {
                foreach ($Item in $Vlan) {
                    try {
                        $inObj = [ordered] @{
                            'Interface Name' = $Item.InterfaceName
                            'Parent Interface' = $Item.ParentInterface
                            'Vlan ID' = $Item.VlanID
                        }
                        $VlanObj += [pscustomobject]$inobj
                    }
                    catch {
                        Write-PscriboMessage -IsWarning $_.Exception.Message
                    }
                }

                $TableParams = @{
                    Name = "Network VLAN - $($Node)"
                    List = $false
                    ColumnWidths = 34, 33, 33
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $VlanObj | Table @TableParams
            }
        }
        catch {
            Write-PscriboMessage -IsWarning $_.Exception.Message
        }
    }

    end {}

}