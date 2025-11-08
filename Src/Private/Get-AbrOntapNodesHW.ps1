function Get-AbrOntapNodesHW {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP system nodes hardware information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.6.7
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
        Write-PScriboMessage "Collecting ONTAP Node Hardware information."
    }

    process {
        try {
            $NodeHW = Get-NcNodeInfo -Controller $Array -ErrorAction Continue
            if ($NodeHW) {
                $Outobj = @()
                foreach ($NodeHWs in $NodeHW) {
                    try {
                        $NodeInfo = Get-NcNode -Node $NodeHWs.SystemName -Controller $Array
                        $Inobj = [ordered] @{
                            'Name' = $NodeHWs.SystemName
                            'System Type' = $NodeHWs.SystemMachineType
                            'CPU Count' = $NodeHWs.NumberOfProcessors
                            'Total Memory' = "$($NodeHWs.MemorySize / 1024)GB"
                            'Vendor' = $NodeHWs.VendorId
                            'AFF/FAS' = $NodeHWs.ProdType
                            'All Flash Optimized' = ConvertTo-TextYN $NodeInfo.IsAllFlashOptimized
                            'Epsilon' = ConvertTo-TextYN $NodeInfo.IsEpsilonNode
                            'System Healthy' = switch ($NodeInfo.IsNodeHealthy) {
                                "True" { "Healthy" }
                                "False" { "UnHealthy" }
                                default { $NodeInfo.IsNodeHealthy }
                            }
                            'Failed Fan Count' = $NodeInfo.EnvFailedFanCount
                            'Failed Fan Error' = $NodeInfo.EnvFailedFanMessage
                            'Failed PowerSupply Count' = $NodeInfo.EnvFailedPowerSupplyCount
                            'Failed PowerSupply Error' = $NodeInfo.EnvFailedPowerSupplyMessage
                            'Over Temperature' = switch ($NodeInfo.EnvOverTemperature) {
                                "True" { "High Temperature" }
                                "False" { "Normal Temperature" }
                                default { $NodeInfo.EnvOverTemperature }
                            }
                            'NVRAM Battery Healthy' = $NodeInfo.NvramBatteryStatus
                        }
                        $Outobj = [PSCustomObject]$Inobj

                        if ($Healthcheck.Node.HW) {
                            $Outobj | Where-Object { $_.'System Healthy' -like 'UnHealthy' } | Set-Style -Style Critical -Property 'System Healthy'
                            $Outobj | Where-Object { $_.'Failed Fan Count' -gt 0 } | Set-Style -Style Critical -Property 'Failed Fan Count'
                            $Outobj | Where-Object { $_.'Failed PowerSupply Count' -gt 0 } | Set-Style -Style Critical -Property 'Failed PowerSupply Count'
                            $Outobj | Where-Object { $_.'Over Temperature' -like 'High Temperature' } | Set-Style -Style Critical -Property 'Over Temperature'
                            $Outobj | Where-Object { $_.'NVRAM Battery Healthy' -notlike 'battery_ok' } | Set-Style -Style Critical -Property 'NVRAM Battery Healthy'
                        }

                        $TableParams = @{
                            Name = "Node Hardware - $($NodeHWs.SystemName)"
                            List = $true
                            ColumnWidths = 40, 60
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $Outobj | Table @TableParams
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning $_.Exception.Message
        }
    }

    end {}

}