function Get-AbrOntapNetworkMgmt {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP network management interfaces information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.6.12
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
        Write-PScriboMessage 'Collecting ONTAP network management interface information.'
    }

    process {
        try {
            $ClusterData = Get-NcNetInterface -Controller $Array | Where-Object { $_.Role -eq 'cluster' }
            if ($ClusterData) {
                try {
                    Section -ExcludeFromTOC -Style Heading6 'Cluster Network Interfaces' {
                        $ClusterObj = @()
                        foreach ($Item in $ClusterData) {
                            try {
                                $inObj = [ordered] @{
                                    'Cluster Interface' = $Item.InterfaceName
                                    'Status' = ${Item}?.OpStatus?.ToString()?.ToUpper()
                                    'Data Protocols' = $Item.DataProtocols
                                    'Address' = $Item.Address
                                    'Home Node' = $Item.HomeNode
                                    'Vserver' = $Item.Vserver
                                }
                                $ClusterObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                            } catch {
                                Write-PScriboMessage -IsWarning $_.Exception.Message
                            }
                        }
                        if ($Healthcheck.Network.Interface) {
                            $ClusterObj | Where-Object { $_.'Status' -notlike 'UP' } | Set-Style -Style Warning -Property 'Status'
                        }

                        $TableParams = @{
                            Name = "Cluster Network - $($ClusterInfo.ClusterName)"
                            List = $false
                            ColumnWidths = 27, 8, 17, 15, 15, 18
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $ClusterObj | Table @TableParams
                        if ($Healthcheck.Network.Interface -and ($ClusterObj | Where-Object { $_.'Status' -notlike 'UP' })) {
                            Paragraph 'Health Check:' -Bold -Underline
                            BlankLine
                            Paragraph {
                                Text 'Best Practice:' -Bold
                                Text 'Ensure that all cluster network interfaces are operational (UP) to maintain cluster connectivity and performance.'
                            }
                            BlankLine
                        }
                    }

                } catch {
                    Write-PScriboMessage -IsWarning $_.Exception.Message
                }
            }
            try {
                $ClusterData = Get-NcNetInterface -Controller $Array | Where-Object { $_.Role -eq 'cluster_mgmt' -or $_.Role -eq 'node_mgmt' }
                if ($ClusterData) {
                    Section -ExcludeFromTOC -Style Heading6 'Management Network Interfaces' {
                        $ClusterObj = @()
                        foreach ($Item in $ClusterData) {
                            try {
                                $inObj = [ordered] @{
                                    'MGMT Interface' = $Item.InterfaceName
                                    'Status' = ${Item}?.OpStatus?.ToString()?.ToUpper()
                                    'Data Protocols' = $Item.DataProtocols
                                    'Address' = $Item.Address
                                    'Home Node' = $Item.HomeNode
                                    'Vserver' = $Item.Vserver
                                }
                                $ClusterObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                            } catch {
                                Write-PScriboMessage -IsWarning $_.Exception.Message
                            }
                        }
                        if ($Healthcheck.Network.Interface) {
                            $ClusterObj | Where-Object { $_.'Status' -notlike 'UP' } | Set-Style -Style Warning -Property 'Status'
                        }

                        $TableParams = @{
                            Name = "Management Network - $($ClusterInfo.ClusterName)"
                            List = $false
                            ColumnWidths = 27, 8, 17, 15, 15, 18
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $ClusterObj | Table @TableParams
                        if ($Healthcheck.Network.Interface -and ($ClusterObj | Where-Object { $_.'Status' -notlike 'UP' })) {
                            Paragraph 'Health Check:' -Bold -Underline
                            BlankLine
                            Paragraph {
                                Text 'Best Practice:' -Bold
                                Text 'Ensure that all management network interfaces are operational (UP) to maintain proper management access to the cluster.'
                            }
                            BlankLine
                        }
                    }
                }
            } catch {
                Write-PScriboMessage -IsWarning $_.Exception.Message
            }
            try {
                $ClusterData = Get-NcNetInterface -Controller $Array | Where-Object { $_.Role -eq 'intercluster' }
                if ($ClusterData) {
                    Section -ExcludeFromTOC -Style Heading6 'Intercluster Network Interfaces' {
                        $ClusterObj = @()
                        foreach ($Item in $ClusterData) {
                            try {
                                $inObj = [ordered] @{
                                    'Intercluster Interface' = $Item.InterfaceName
                                    'Status' = ${Item}?.OpStatus?.ToString()?.ToUpper()
                                    'Data Protocols' = $Item.DataProtocols
                                    'Address' = $Item.Address
                                    'Home Node' = $Item.HomeNode
                                    'Vserver' = $Item.Vserver
                                }
                                $ClusterObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                            } catch {
                                Write-PScriboMessage -IsWarning $_.Exception.Message
                            }
                        }
                        if ($Healthcheck.Network.Interface) {
                            $ClusterObj | Where-Object { $_.'Status' -notlike 'UP' } | Set-Style -Style Warning -Property 'Status'
                        }

                        $TableParams = @{
                            Name = "Intercluster Network - $($ClusterInfo.ClusterName)"
                            List = $false
                            ColumnWidths = 27, 8, 17, 15, 15, 18
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $ClusterObj | Table @TableParams
                        if ($Healthcheck.Network.Interface -and ($ClusterObj | Where-Object { $_.'Status' -notlike 'UP' })) {
                            Paragraph 'Health Check:' -Bold -Underline
                            BlankLine
                            Paragraph {
                                Text 'Best Practice:' -Bold
                                Text 'Ensure that all intercluster network interfaces are operational (UP) to maintain cluster-to-cluster communication.'
                            }
                            BlankLine
                        }

                    }
                }
            } catch {
                Write-PScriboMessage -IsWarning $_.Exception.Message
            }
            try {
                $ClusterData = Get-NcNetInterface -Controller $Array | Where-Object { $_.Role -eq 'data' -and $_.Vserver -notin $options.Exclude.Vserver }
                if ($ClusterData) {
                    Section -ExcludeFromTOC -Style Heading6 'Data Network Interfaces' {
                        $ClusterObj = @()
                        foreach ($Item in $ClusterData) {
                            try {
                                if ($Item.Wwpn) {
                                    $AddressData = $Item.Wwpn
                                } else { $AddressData = $Item.Address }
                                $inObj = [ordered] @{
                                    'Data Interface' = $Item.InterfaceName
                                    'Status' = ${Item}?.OpStatus?.ToString()?.ToUpper()
                                    'Data Protocols' = [string]$Item.DataProtocols
                                    'Address' = $AddressData
                                    'Home Node' = $Item.HomeNode
                                    'Vserver' = $Item.Vserver
                                }
                                $ClusterObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                            } catch {
                                Write-PScriboMessage -IsWarning $_.Exception.Message
                            }
                        }
                        if ($Healthcheck.Network.Interface) {
                            $ClusterObj | Where-Object { $_.'Status' -notlike 'UP' } | Set-Style -Style Warning -Property 'Status'
                        }

                        $TableParams = @{
                            Name = "Data Network - $($ClusterInfo.ClusterName)"
                            List = $false
                            ColumnWidths = 25, 10, 17, 15, 15, 18
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $ClusterObj | Table @TableParams
                        if ($Healthcheck.Network.Interface -and ($ClusterObj | Where-Object { $_.'Status' -notlike 'UP' })) {
                            Paragraph 'Health Check:' -Bold -Underline
                            BlankLine
                            Paragraph {
                                Text 'Best Practice:' -Bold
                                Text 'Ensure that all data network interfaces are operational (UP) to maintain optimal data access and performance.'
                            }
                            BlankLine
                        }
                    }
                }
            } catch {
                Write-PScriboMessage -IsWarning $_.Exception.Message
            }
            try {
                $ClusterData = Get-NcNetInterface -Controller $Array | Where-Object { $_.DataProtocols -ne 'fcp' -and $_.IsHome -like 'False' }
                if ($ClusterData) {
                    Section -ExcludeFromTOC -Style Heading6 'Network Interfaces Home Status' {
                        Paragraph "The following table provides the LIF Home Status Information from $($ClusterInfo.ClusterName)."
                        BlankLine
                        $ClusterObj = @()
                        foreach ($Item in $ClusterData) {
                            try {
                                $inObj = [ordered] @{
                                    'Network Interface' = $Item.InterfaceName
                                    'Home Port' = $Item.HomeNode + ':' + $Item.HomePort
                                    'Current Port' = $Item.CurrentNode + ':' + $Item.CurrentPort
                                    'IsHome' = ($Item.IsHome -eq $True) ? 'Yes': 'No'
                                    'Vserver' = $Item.Vserver
                                }
                                $ClusterObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                            } catch {
                                Write-PScriboMessage -IsWarning $_.Exception.Message
                            }
                        }
                        if ($Healthcheck.Network.Interface) {
                            $ClusterObj | Where-Object { $_.'IsHome' -ne 'Yes' } | Set-Style -Style Warning -Property 'Network Interface', 'IsHome', 'Home Port', 'Current Port', 'Vserver'
                        }

                        $TableParams = @{
                            Name = "Network Interfaces Home Status - $($ClusterInfo.ClusterName)"
                            List = $false
                            ColumnWidths = 20, 25, 25, 10, 20
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $ClusterObj | Table @TableParams
                        if ($Healthcheck.Network.Interface -and ($ClusterObj | Where-Object { $_.'IsHome' -ne 'Yes' })) {
                            Paragraph 'Health Check:' -Bold -Underline
                            BlankLine
                            Paragraph {
                                Text 'Best Practice:' -Bold
                                Text 'Ensure that all network interfaces are on their designated home ports to maintain optimal network performance and reliability.'
                            }
                            BlankLine
                        }

                    }
                }
            } catch {
                Write-PScriboMessage -IsWarning $_.Exception.Message
            }
        } catch {
            Write-PScriboMessage -IsWarning $_.Exception.Message
        }
    }

    end {}

}