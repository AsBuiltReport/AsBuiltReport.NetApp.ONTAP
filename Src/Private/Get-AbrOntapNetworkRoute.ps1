function Get-AbrOntapNetworkRoute {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP network Route information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.6.7
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
        Write-PScriboMessage "Collecting ONTAP network route information."
    }

    process {
        try {
            $Routes = Get-NcNetRoute -VserverContext $Vserver -Controller $Array
            $RoutesObj = @()
            if ($Routes) {
                foreach ($Item in $Routes) {
                    try {
                        $inObj = [ordered] @{
                            'Destination' = $Item.Destination
                            'Gateway' = $Item.Gateway
                            'Metric' = $Item.Metric
                            'Address Family' = $Item.AddressFamily.ToString().ToUpper()
                        }
                        $RoutesObj += [pscustomobject]$inobj
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }

                $TableParams = @{
                    Name = "Network Route - $($Vserver)"
                    List = $false
                    ColumnWidths = 30, 30, 20, 20
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $RoutesObj | Table @TableParams
            }
        } catch {
            Write-PScriboMessage -IsWarning $_.Exception.Message
        }
    }

    end {}

}