function Get-AbrOntapNetworkRoutes {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP network Route information from the Cluster Management Network
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
            $Vserver
    )

    begin {
        Write-PscriboMessage "Collecting ONTAP network route information."
    }

    process {
        $Routes = Get-NcNetRoute -VserverContext $Vserver
        $RoutesObj = @()
        if ($Routes) {
            foreach ($Item in $Routes) {
                $inObj = [ordered] @{
                    'Destination' = $Item.Destination
                    'Gateway' = $Item.Gateway
                    'Metric' = $Item.Metric
                    'Address Family' = $Item.AddressFamily.ToString().ToUpper()
                }
                $RoutesObj += [pscustomobject]$inobj
            }

            $TableParams = @{
                Name = "Network Route Information - $($Vserver)"
                List = $false
                ColumnWidths = 30, 30, 20, 20
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $RoutesObj | Table @TableParams
        }
    }

    end {}

}