function Get-AbrOntapNetworkPorts {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP physical interface port information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.3.0
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
        Write-PscriboMessage "Collecting ONTAP physical interface information."
    }

    process {
        $PhysicalPorts = Get-NcNetPort | Where-Object {$_.PortType -like 'physical'}
        if ($PhysicalPorts) {
            $PhysicalNic = foreach ($Nics in $PhysicalPorts) {
                [PSCustomObject] @{
                    'Port Name' = $Nics.Port
                    'Role' = $Nics.Role
                    'Link Status' = $Nics.LinkStatus
                    'Node Owner' = $Nics.Node
                    'Mac Address' = $Nics.MacAddress
                    'MTU' = $Nics.MTU
                    'Admin State' = $Nics.IsAdministrativeUp
                }
            }
            if ($Healthcheck.Network.Port) {
                $PhysicalNic | Where-Object { $_.'Link Status' -like 'down' -and $_.'Admin State' -like 'True' } | Set-Style -Style Warning -Property 'Link Status'
            }

            $TableParams = @{
                Name = "Physical Port Information - $($ClusterInfo.ClusterName)"
                List = $false
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $PhysicalNic | Table @TableParams
        }
    }

    end {}

}