function Get-AbrOntapNetworkMgmt {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP network management interfaces information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.6.6
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
        Write-PscriboMessage "Collecting ONTAP network management interface information."
    }

    process {
        try {
            if (Get-NcNetInterface -Controller $Array | Where-Object {$_.Role -eq 'cluster'}) {
                try {
                    Section -ExcludeFromTOC -Style Heading6 'Cluster Network Interfaces' {
                        $ClusterData = Get-NcNetInterface -Controller $Array | Where-Object {$_.Role -eq 'cluster'}
                        $ClusterObj = @()
                        if ($ClusterData) {
                            foreach ($Item in $ClusterData) {
                                try {
                                    $inObj = [ordered] @{
                                        'Cluster Interface' = $Item.InterfaceName
                                        'Status' = Switch ($Item.OpStatus) {
                                            "" {"Unknown"}
                                            $Null {"Unknown"}
                                            default {$Item.OpStatus.ToString().ToUpper()}
                                        }
                                        'Data Protocols' = $Item.DataProtocols
                                        'Address' = $Item.Address
                                        'Vserver' = $Item.Vserver
                                    }
                                    $ClusterObj += [pscustomobject]$inobj
                                }
                                catch {
                                    Write-PscriboMessage -IsWarning $_.Exception.Message
                                }
                            }
                            if ($Healthcheck.Network.Interface) {
                                $ClusterObj | Where-Object { $_.'Status' -notlike 'UP' } | Set-Style -Style Warning -Property 'Status'
                            }

                            $TableParams = @{
                                Name = "Cluster Network - $($ClusterInfo.ClusterName)"
                                List = $false
                                ColumnWidths = 35, 8, 21, 18, 18
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $ClusterObj | Table @TableParams
                        }
                    }
                }
                catch {
                    Write-PscriboMessage -IsWarning $_.Exception.Message
                }
            }
            try {
                Section -ExcludeFromTOC -Style Heading6 'Management Network Interfaces' {
                    $ClusterData = Get-NcNetInterface -Controller $Array | Where-Object {$_.Role -eq 'cluster_mgmt' -or $_.Role -eq 'node_mgmt'}
                    $ClusterObj = @()
                    if ($ClusterData) {
                        foreach ($Item in $ClusterData) {
                            try {
                                $inObj = [ordered] @{
                                    'MGMT Interface' = $Item.InterfaceName
                                    'Status' = Switch ($Item.OpStatus) {
                                        "" {"Unknown"}
                                        $Null {"Unknown"}
                                        default {$Item.OpStatus.ToString().ToUpper()}
                                    }
                                    'Data Protocols' = $Item.DataProtocols
                                    'Address' = $Item.Address
                                    'Vserver' = $Item.Vserver
                                }
                                $ClusterObj += [pscustomobject]$inobj
                            }
                            catch {
                                Write-PscriboMessage -IsWarning $_.Exception.Message
                            }
                        }
                        if ($Healthcheck.Network.Interface) {
                            $ClusterObj | Where-Object { $_.'Status' -notlike 'UP' } | Set-Style -Style Warning -Property 'Status'
                        }

                        $TableParams = @{
                            Name = "Management Network - $($ClusterInfo.ClusterName)"
                            List = $false
                            ColumnWidths = 35, 8, 21, 18, 18
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $ClusterObj | Table @TableParams
                    }
                }
            }
            catch {
                Write-PscriboMessage -IsWarning $_.Exception.Message
            }
            try {
                if (Get-NcNetInterface -Controller $Array | Where-Object {$_.Role -eq 'intercluster'}) {
                    Section -ExcludeFromTOC -Style Heading6 'Intercluster Network Interfaces' {
                        $ClusterData = Get-NcNetInterface -Controller $Array | Where-Object {$_.Role -eq 'intercluster'}
                        $ClusterObj = @()
                        if ($ClusterData) {
                            foreach ($Item in $ClusterData) {
                                try {
                                    $inObj = [ordered] @{
                                        'Intercluster Interface' = $Item.InterfaceName
                                        'Status' = Switch ($Item.OpStatus) {
                                            "" {"Unknown"}
                                            $Null {"Unknown"}
                                            default {$Item.OpStatus.ToString().ToUpper()}
                                        }
                                        'Data Protocols' = $Item.DataProtocols
                                        'Address' = $Item.Address
                                        'Vserver' = $Item.Vserver
                                    }
                                    $ClusterObj += [pscustomobject]$inobj
                                }
                                catch {
                                    Write-PscriboMessage -IsWarning $_.Exception.Message
                                }
                            }
                            if ($Healthcheck.Network.Interface) {
                                $ClusterObj | Where-Object { $_.'Status' -notlike 'UP' } | Set-Style -Style Warning -Property 'Status'
                            }

                            $TableParams = @{
                                Name = "Intercluster Network - $($ClusterInfo.ClusterName)"
                                List = $false
                                ColumnWidths = 35, 8, 21, 18, 18
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $ClusterObj | Table @TableParams
                        }
                    }
                }
            }
            catch {
                Write-PscriboMessage -IsWarning $_.Exception.Message
            }
            try {
                Section -ExcludeFromTOC -Style Heading6 'Data Network Interfaces' {
                    $ClusterData = Get-NcNetInterface -Controller $Array | Where-Object {$_.Role -eq 'data' -and $_.DataProtocols -ne 'fcp' -and $_.Vserver -notin $options.Exclude.Vserver}
                    $ClusterObj = @()
                    if ($ClusterData) {
                        foreach ($Item in $ClusterData) {
                            try {
                                $inObj = [ordered] @{
                                    'Data Interface' = $Item.InterfaceName
                                    'Status' = Switch ($Item.OpStatus) {
                                        "" {"Unknown"}
                                        $Null {"Unknown"}
                                        default {$Item.OpStatus.ToString().ToUpper()}
                                    }
                                    'Data Protocols' = [string]$Item.DataProtocols
                                    'Address' = $Item.Address
                                    'Vserver' = $Item.Vserver
                                }
                                $ClusterObj += [pscustomobject]$inobj
                            }
                            catch {
                                Write-PscriboMessage -IsWarning $_.Exception.Message
                            }
                        }
                        if ($Healthcheck.Network.Interface) {
                            $ClusterObj | Where-Object { $_.'Status' -notlike 'UP' } | Set-Style -Style Warning -Property 'Status'
                        }

                        $TableParams = @{
                            Name = "Data Network - $($ClusterInfo.ClusterName)"
                            List = $false
                            ColumnWidths = 33, 10, 21, 18, 18
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $ClusterObj | Table @TableParams
                    }
                }
            }
            catch {
                Write-PscriboMessage -IsWarning $_.Exception.Message
            }
            try {
                if ((Get-NcNetInterface -Controller $Array | Where-Object { $_.DataProtocols -ne 'fcp' -and $_.IsHome -like "False"}) -and $Healthcheck.Network.Interface) {
                    Section -ExcludeFromTOC -Style Heading6 'HealthCheck - Check If Network Interface is Home' {
                        Paragraph "The following section provides the LIF Home Status Information on $($ClusterInfo.ClusterName)."
                        BlankLine
                        $ClusterData = Get-NcNetInterface -Controller $Array | Where-Object { $_.DataProtocols -ne 'fcp' -and $_.IsHome -like "False"}
                        $ClusterObj = @()
                        if ($ClusterData) {
                            foreach ($Item in $ClusterData) {
                                try {
                                    $inObj = [ordered] @{
                                        'Network Interface' = $Item.InterfaceName
                                        'Home Port' = $Item.HomeNode + ":" + $Item.HomePort
                                        'Current Port' = $Item.CurrentNode + ":" + $Item.CurrentPort
                                        'IsHome' = Switch ($Item.IsHome) {
                                            "True" { 'Yes' }
                                            "False" { "No" }
                                            default {$Item.IsHome}
                                        }
                                        'Vserver' = $Item.Vserver
                                    }
                                    $ClusterObj += [pscustomobject]$inobj
                                }
                                catch {
                                    Write-PscriboMessage -IsWarning $_.Exception.Message
                                }
                            }
                            if ($Healthcheck.Network.Interface) {
                                $ClusterObj | Where-Object { $_.'IsHome' -ne 'Yes' } | Set-Style -Style Warning -Property 'Network Interface','IsHome','Home Port','Current Port','Vserver'
                            }

                            $TableParams = @{
                                Name = "Network Interface Home Status - $($ClusterInfo.ClusterName)"
                                List = $false
                                ColumnWidths = 20, 25, 25, 10, 20
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $ClusterObj | Table @TableParams
                        }
                    }
                }
            }
            catch {
                Write-PscriboMessage -IsWarning $_.Exception.Message
            }
        }
        catch {
            Write-PscriboMessage -IsWarning $_.Exception.Message
        }
    }

    end {}

}