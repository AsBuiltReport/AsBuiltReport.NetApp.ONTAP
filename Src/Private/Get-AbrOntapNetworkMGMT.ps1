function Get-AbrOntapNetworkMgmt {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP network management interfaces information from the Cluster Management Network
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
        Write-PscriboMessage "Collecting ONTAP network management interface information."
    }

    process {
        $ClusterData = Get-NcNetInterface | Where-Object {$_.Role -eq 'cluster'}
        $ClusterObj = @()
        if ($ClusterData) {
            foreach ($Item in $ClusterData) {
                $inObj = [ordered] @{
                    'Cluster Interface' = $Item.InterfaceName
                    'Status' = $Item.OpStatus
                    'Data Protocols' = $Item.DataProtocols
                    'Vserver' = $Item.Vserver
                    'Address' = $Item.Address
                }
                $ClusterObj += [pscustomobject]$inobj
            }
            if ($Healthcheck.Network.Interface) {
                $ClusterObj | Where-Object { $_.'Status' -notlike 'up' } | Set-Style -Style Warning -Property 'Status'
            }

            $TableParams = @{
                Name = "Cluster Network Information - $($ClusterInfo.ClusterName)"
                List = $false
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $ClusterObj | Table @TableParams
        }
        $ClusterData = Get-NcNetInterface | Where-Object {$_.Role -eq 'cluster_mgmt' -or $_.Role -eq 'node_mgmt'}
        $ClusterObj = @()
        if ($ClusterData) {
            foreach ($Item in $ClusterData) {
                $inObj = [ordered] @{
                    'MGMT Interface' = $Item.InterfaceName
                    'Status' = $Item.OpStatus
                    'Data Protocols' = $Item.DataProtocols
                    'Vserver' = $Item.Vserver
                    'Address' = $Item.Address
                }
                $ClusterObj += [pscustomobject]$inobj
            }
            if ($Healthcheck.Network.Interface) {
                $ClusterObj | Where-Object { $_.'Status' -notlike 'up' } | Set-Style -Style Warning -Property 'Status'
            }

            $TableParams = @{
                Name = "Cluster MGMT Network Information - $($ClusterInfo.ClusterName)"
                List = $false
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $ClusterObj | Table @TableParams
        }
        $ClusterData = Get-NcNetInterface | Where-Object {$_.Role -eq 'intercluster'}
        $ClusterObj = @()
        if ($ClusterData) {
            foreach ($Item in $ClusterData) {
                $inObj = [ordered] @{
                    'Intercluster Interface' = $Item.InterfaceName
                    'Status' = $Item.OpStatus
                    'Data Protocols' = $Item.DataProtocols
                    'Vserver' = $Item.Vserver
                    'Address' = $Item.Address
                }
                $ClusterObj += [pscustomobject]$inobj
            }
            if ($Healthcheck.Network.Interface) {
                $ClusterObj | Where-Object { $_.'Status' -notlike 'up' } | Set-Style -Style Warning -Property 'Status'
            }

            $TableParams = @{
                Name = "Cluster Intercluster Network Information - $($ClusterInfo.ClusterName)"
                List = $false
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $ClusterObj | Table @TableParams
        }
        $ClusterData = Get-NcNetInterface | Where-Object {$_.Role -eq 'data'}
        $ClusterObj = @()
        if ($ClusterData) {
            foreach ($Item in $ClusterData) {
                $inObj = [ordered] @{
                    'Data Interface' = $Item.InterfaceName
                    'Status' = $Item.OpStatus
                    'Data Protocols' = $Item.DataProtocols
                    'Vserver' = $Item.Vserver
                    'Address' = $Item.Address
                }
                $ClusterObj += [pscustomobject]$inobj
            }
            if ($Healthcheck.Network.Interface) {
                $ClusterObj | Where-Object { $_.'Status' -notlike 'up' } | Set-Style -Style Warning -Property 'Status'
            }

            $TableParams = @{
                Name = "Cluster Data Network Information - $($ClusterInfo.ClusterName)"
                List = $false
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $ClusterObj | Table @TableParams
        }
    }

    end {}

}