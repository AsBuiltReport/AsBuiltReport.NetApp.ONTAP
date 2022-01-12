function Get-AbrOntapNetworkPort {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP physical interface port information from the Cluster Management Network
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
            $Node
    )

    begin {
        Write-PscriboMessage "Collecting ONTAP physical interface information."
    }

    process {
        $PhysicalPorts = Get-NcNetPort -Node $Node -Controller $Array | Where-Object {$_.PortType -like 'physical'}
        if ($PhysicalPorts) {
            $PhysicalNic = foreach ($Nics in $PhysicalPorts) {
                [PSCustomObject] @{
                    'Port Name' = $Nics.Port
                    'Role' = $TextInfo.ToTitleCase($Nics.Role)
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
                Name = "Physical Port - $($Node)"
                List = $false
                ColumnWidths = 20, 20, 30, 10, 10, 10
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $PhysicalNic | Table @TableParams
        }
    }

    end {}

}