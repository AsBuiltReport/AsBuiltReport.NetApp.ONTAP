function Get-AbrOntapNetworkRouteLif {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP network route per lif information from the Cluster Management Network
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
            $Vserver
    )

    begin {
        Write-PscriboMessage "Collecting ONTAP network route per lif information."
    }

    process {
        try {
            $Routes = Get-NcNetRouteLif -VserverContext $Vserver -Controller $Array
            $RoutesObj = @()
            if ($Routes) {
                foreach ($Item in $Routes) {
                    try {
                        $inObj = [ordered] @{
                            'Destination' = $Item.Destination
                            'Gateway' = $Item.Gateway
                            'Lif Names' = $Item.LifNames
                            'Address Family' = $Item.AddressFamily.ToString().ToUpper()
                        }
                        $RoutesObj += [pscustomobject]$inobj
                    }
                    catch {
                        Write-PscriboMessage -IsWarning $_.Exception.Message
                    }
                }

                $TableParams = @{
                    Name = "Per Network Interface Route - $($Vserver)"
                    List = $false
                    ColumnWidths = 20, 20, 40, 20
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $RoutesObj | Table @TableParams
            }
        }
        catch {
            Write-PscriboMessage -IsWarning $_.Exception.Message
        }
    }

    end {}

}