function Get-AbrOntapVserverFcpInterface {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP Vserver FCP interface information from the Cluster Management Network
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
        Write-PscriboMessage "Collecting ONTAP Vserver FCP interface information."
    }

    process {
        $VserverData = Get-NcFcpInterface
        $VserverObj = @()
        if ($VserverData) {
            foreach ($Item in $VserverData) {
                $inObj = [ordered] @{
                    'Interface Name' = $Item.InterfaceName
                    'FCP WWPN' = $Item.PortName
                    'Home Port' = $Item.CurrentPort
                    'Vserver' = $Item.Vserver
                }
                $VserverObj += [pscustomobject]$inobj
            }

            $TableParams = @{
                Name = "FCP Interface Information - $($ClusterInfo.ClusterName)"
                List = $false
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $VserverObj | Table @TableParams
        }
    }

    end {}

}