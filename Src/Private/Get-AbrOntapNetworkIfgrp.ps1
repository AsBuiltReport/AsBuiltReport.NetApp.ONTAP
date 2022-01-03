function Get-AbrOntapNetworkIfgrp {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP aggregate interface port information from the Cluster Management Network
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
        Write-PscriboMessage "Collecting ONTAP physical aggregata interface information."
    }

    process {
        $IFGRPPorts = Get-NcNetPortIfgrp -Node $Node -Controller $Array
        $AggregatePorts = @()
        if ($IFGRPPorts) {
            foreach ($Nics in $IFGRPPorts) {
                if ($Nics.DownPorts) {
                    $UPPort = "$($Nics.UpPorts) $($Nics.DownPorts)(Down)"
                }else {$UPPort = [String]$Nics.UpPorts}
                $inObj = [ordered] @{
                    'Port Name' = $Nics.IfgrpName
                    'Distribution Function' = $Nics.DistributionFunction
                    'Mode' = $Nics.Mode
                    'Port' = $UPPort
                    'Mac Address' = $Nics.MacAddress
                    'Port Participation' = $Nics.PortParticipation
                }
                $AggregatePorts += [pscustomobject]$inobj
            }
            if ($Healthcheck.Network.Port) {
                $AggregatePorts | Where-Object { $_.'Port' -match "Down" } | Set-Style -Style Warning -Property 'Port'
                $AggregatePorts | Where-Object { $_.'Port Participation' -ne "full" } | Set-Style -Style Warning -Property 'Port Participation'
            }


            $TableParams = @{
                Name = "Link Aggregation Group - $($Node)"
                List = $false
                ColumnWidths = 15, 15, 15 ,20 ,20, 15
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $AggregatePorts | Table @TableParams
        }
    }

    end {}

}