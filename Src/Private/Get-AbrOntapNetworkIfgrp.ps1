function Get-AbrOntapNetworkIfgrp {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP aggregate interface port information from the Cluster Management Network
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
        $Node
    )

    begin {
        Write-PScriboMessage "Collecting ONTAP physical aggregata interface information."
    }

    process {
        try {
            $IFGRPPorts = Get-NcNetPortIfgrp -Node $Node -Controller $Array
            $AggregatePorts = @()
            if ($IFGRPPorts) {
                foreach ($Nics in $IFGRPPorts) {
                    try {
                        if ($Nics.DownPorts) {
                            $UPPort = "$($Nics.UpPorts) $($Nics.DownPorts)(Down)"
                        } else { $UPPort = [String]$Nics.UpPorts }
                        $inObj = [ordered] @{
                            'Port Name' = $Nics.IfgrpName
                            'Distribution Function' = $Nics.DistributionFunction
                            'Mode' = $Nics.Mode
                            'Port' = $UPPort
                            'Mac Address' = $Nics.MacAddress
                            'Port Participation' = $Nics.PortParticipation
                        }
                        $AggregatePorts += [pscustomobject]$inobj
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }
                if ($Healthcheck.Network.Port) {
                    $AggregatePorts | Where-Object { $_.'Port' -match "Down" } | Set-Style -Style Warning -Property 'Port'
                    $AggregatePorts | Where-Object { $_.'Port Participation' -ne "full" } | Set-Style -Style Warning -Property 'Port Participation'
                }


                $TableParams = @{
                    Name = "Link Aggregation Group - $($Node)"
                    List = $false
                    ColumnWidths = 15, 15, 15 , 20 , 20, 15
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $AggregatePorts | Table @TableParams
                if ($Healthcheck.Network.Port -and ($AggregatePorts | Where-Object { $_.'Port Participation' -ne "full" })) {
                    Paragraph "Health Check:" -Bold -Underline
                    BlankLine
                    Paragraph {
                        Text "Best Practice:" -Bold
                        Text "Ensure that all ports in the interface group are active and participating fully to maintain optimal network performance and redundancy."
                    }
                    BlankLine
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning $_.Exception.Message
        }
    }

    end {}

}