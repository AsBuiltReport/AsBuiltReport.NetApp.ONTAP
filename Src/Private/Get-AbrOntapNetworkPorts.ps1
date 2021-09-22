function Get-AbrOntapNetworkPorts {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP physical interface port information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.4.0
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
                    'Role' = $TextInfo.ToTitleCase($Nics.Role)
                    'Node Owner' = $Nics.Node
                    'Mac Address' = $Nics.MacAddress
                    'MTU' = $Nics.MTU
                    'Link Status' = $TextInfo.ToTitleCase($Nics.LinkStatus)
                    'Admin Status' = Switch ($Nics.IsAdministrativeUp) {
                        "True" { 'Up' }
                        "False" { 'Down' }
                        default { $Nics.IsAdministrativeUp }
                    }
                }
            }
            if ($Healthcheck.Network.Port) {
                $PhysicalNic | Where-Object { $_.'Link Status' -like 'down' -and $_.'Admin Status' -like 'Up' } | Set-Style -Style Warning -Property 'Link Status'
            }

            $TableParams = @{
                Name = "Physical Port Information - $($ClusterInfo.ClusterName)"
                List = $false
                ColumnWidths = 15, 15, 22, 20, 10, 8, 10
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $PhysicalNic | Table @TableParams
        }
    }

    end {}

}