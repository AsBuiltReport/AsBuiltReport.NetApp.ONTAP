function Get-AbrOntapNetworkMgmt {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP network management interfaces information from the Cluster Management Network
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
        Write-PscriboMessage "Collecting ONTAP network management interface information."
    }

    process {
        if (Get-NcNetInterface | Where-Object {$_.Role -eq 'cluster'}) {
            Section -Style Heading6 'Cluster Network Interfaces Summary' {
                Paragraph "The following section provides the Cluster Network Interfaces Information on $($ClusterInfo.ClusterName)."
                BlankLine
                $ClusterData = Get-NcNetInterface | Where-Object {$_.Role -eq 'cluster'}
                $ClusterObj = @()
                if ($ClusterData) {
                    foreach ($Item in $ClusterData) {
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
                    if ($Healthcheck.Network.Interface) {
                        $ClusterObj | Where-Object { $_.'Status' -notlike 'UP' } | Set-Style -Style Warning -Property 'Status'
                    }

                    $TableParams = @{
                        Name = "Cluster Network Information - $($ClusterInfo.ClusterName)"
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
        Section -Style Heading6 'Management Network Interfaces Summary' {
            Paragraph "The following section provides the Management Network Interfaces Information on $($ClusterInfo.ClusterName)."
            BlankLine
            $ClusterData = Get-NcNetInterface | Where-Object {$_.Role -eq 'cluster_mgmt' -or $_.Role -eq 'node_mgmt'}
            $ClusterObj = @()
            if ($ClusterData) {
                foreach ($Item in $ClusterData) {
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
                if ($Healthcheck.Network.Interface) {
                    $ClusterObj | Where-Object { $_.'Status' -notlike 'UP' } | Set-Style -Style Warning -Property 'Status'
                }

                $TableParams = @{
                    Name = "Management Network Information - $($ClusterInfo.ClusterName)"
                    List = $false
                    ColumnWidths = 35, 8, 21, 18, 18
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $ClusterObj | Table @TableParams
            }
        }
        if (Get-NcNetInterface | Where-Object {$_.Role -eq 'intercluster'}) {
            Section -Style Heading6 'Intercluster Network Interfaces Summary' {
                Paragraph "The following section provides the Intercluster Network Interfaces Information on $($ClusterInfo.ClusterName)."
                BlankLine
                $ClusterData = Get-NcNetInterface | Where-Object {$_.Role -eq 'intercluster'}
                $ClusterObj = @()
                if ($ClusterData) {
                    foreach ($Item in $ClusterData) {
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
                    if ($Healthcheck.Network.Interface) {
                        $ClusterObj | Where-Object { $_.'Status' -notlike 'UP' } | Set-Style -Style Warning -Property 'Status'
                    }

                    $TableParams = @{
                        Name = "Intercluster Network Information - $($ClusterInfo.ClusterName)"
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
        Section -Style Heading6 'Data Network Interfaces Summary' {
            Paragraph "The following section provides the Data Network Interfaces Information on $($ClusterInfo.ClusterName)."
            BlankLine
            $ClusterData = Get-NcNetInterface | Where-Object {$_.Role -eq 'data' -and $_.DataProtocols -ne 'fcp'}
            $ClusterObj = @()
            if ($ClusterData) {
                foreach ($Item in $ClusterData) {
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
                if ($Healthcheck.Network.Interface) {
                    $ClusterObj | Where-Object { $_.'Status' -notlike 'UP' } | Set-Style -Style Warning -Property 'Status'
                }

                $TableParams = @{
                    Name = "Data Network Information - $($ClusterInfo.ClusterName)"
                    List = $false
                    ColumnWidths = 33, 10, 21, 18, 18
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $ClusterObj | Table @TableParams
            }
        }
        if ((Get-NcNetInterface | Where-Object { $_.DataProtocols -ne 'fcp' -and $_.IsHome -like "False"}) -and $Healthcheck.Network.Interface) {
            Section -Style Heading6 'HealthCheck - Check If Network Interface is Home' {
                Paragraph "The following section provides the LIF Home Status Information on $($ClusterInfo.ClusterName)."
                BlankLine
                $ClusterData = Get-NcNetInterface | Where-Object { $_.DataProtocols -ne 'fcp' -and $_.IsHome -like "False"}
                $ClusterObj = @()
                if ($ClusterData) {
                    foreach ($Item in $ClusterData) {
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
                    if ($Healthcheck.Network.Interface) {
                        $ClusterObj | Where-Object { $_.'IsHome' -ne 'Yes' } | Set-Style -Style Warning -Property 'Network Interface','IsHome','Home Port','Current Port','Vserver'
                    }

                    $TableParams = @{
                        Name = "Network Interface Home Status Information - $($ClusterInfo.ClusterName)"
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

    end {}

}