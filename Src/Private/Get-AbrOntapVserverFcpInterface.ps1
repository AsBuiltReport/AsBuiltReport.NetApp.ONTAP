function Get-AbrOntapVserverFcpInterface {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP Vserver FCP interface information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.6.2
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
        Write-PscriboMessage "Collecting ONTAP Vserver FCP interface information."
    }

    process {
        $VserverData = Get-NcFcpInterface -VserverContext $Vserver -Controller $Array
        $VserverObj = @()
        if ($VserverData) {
            foreach ($Item in $VserverData) {
                $inObj = [ordered] @{
                    'Interface Name' = $Item.InterfaceName
                    'FCP WWPN' = $Item.PortName
                    'Home Port' = $Item.CurrentPort
                }
                $VserverObj += [pscustomobject]$inobj
            }

            $TableParams = @{
                Name = "FCP Interface - $($Vserver)"
                List = $false
                ColumnWidths = 35, 35, 30
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $VserverObj | Table @TableParams
        }
    }

    end {}

}