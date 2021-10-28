function Get-AbrOntapNetworkRouteLif {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP network route per lif information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.5.0
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
        Write-PscriboMessage "Collecting ONTAP network route per lif information."
    }

    process {
        $Routes = Get-NcNetRouteLif -VserverContext $Vserver -Controller $Array
        $RoutesObj = @()
        if ($Routes) {
            foreach ($Item in $Routes) {
                $inObj = [ordered] @{
                    'Destination' = $Item.Destination
                    'Gateway' = $Item.Gateway
                    'Lif Names' = $Item.LifNames
                    'Address Family' = $Item.AddressFamily.ToString().ToUpper()
                }
                $RoutesObj += [pscustomobject]$inobj
            }

            $TableParams = @{
                Name = "Per Network Interface Route Information - $($Vserver)"
                List = $false
                ColumnWidths = 20, 20, 40, 20
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $RoutesObj | Table @TableParams
        }
    }

    end {}

}