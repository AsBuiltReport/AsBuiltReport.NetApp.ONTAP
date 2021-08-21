function Get-AbrOntapVserverNFSOptions {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP Vserver NFS Options information from the Cluster Management Network
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
        Write-PscriboMessage "Collecting ONTAP Vserver NFS Option information."
    }

    process {
        $VserverData = Get-NcNfsService
        $VserverObj = @()
        if ($VserverData) {
            foreach ($Item in $VserverData) {
                $inObj = [ordered] @{
                    'Vserver' = $Item.Vserver
                    'Allow Idle Connection' = $Item.AllowIdleConnection
                    'Idle Connection Timeout' = $Item.IdleConnectionTimeout
                    'Ignore NtAcl For Root' = $Item.IgnoreNtAclForRoot
                    'Enable Ejukebox' = $Item.EnableEjukebox
                    'Nfs Access Enabled' = $Item.IsNfsAccessEnabled
                    'Nfs Rootonly Enabled' = $Item.IsNfsRootonlyEnabled
                    'Nfsv2 Enabled' = $Item.IsNfsv2Enabled
                    'Nfsv3 Enabled' = $Item.IsNfsv3Enabled
                    'Nfsv3 64bit Identifiers Enabled' = $Item.IsNfsv364bitIdentifiersEnabled
                    'Nfsv3 Connection Drop Enabled' = $Item.IsNfsv3ConnectionDropEnabled
                    'Nfsv3 Fsid Change Enabled' = $Item.IsNfsv3FsidChangeEnabled
                    'Nfsv40 Acl Enabled' = $Item.IsNfsv40AclEnabled
                    'Nfsv40 Enabled' = $Item.IsNfsv40Enabled
                }
                $VserverObj += [pscustomobject]$inobj
            }

            $TableParams = @{
                Name = "Vserver NFS Service Options Summary - $($ClusterInfo.ClusterName)"
                List = $true
                ColumnWidths = 50, 50
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $VserverObj | Table @TableParams
        }
    }

    end {}

}