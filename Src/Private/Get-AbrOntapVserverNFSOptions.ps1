function Get-AbrOntapVserverNFSOption {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP Vserver NFS Options information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.6.12
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
        $Vserver
    )

    begin {
        Write-PScriboMessage 'Collecting ONTAP Vserver NFS Option information.'
    }

    process {
        try {
            $VserverData = Get-NcNfsService -VserverContext $Vserver -Controller $Array
            $VserverObj = @()
            if ($VserverData) {
                foreach ($Item in $VserverData) {
                    try {
                        $inObj = [ordered] @{
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
                        $VserverObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }

                $TableParams = @{
                    Name = "NFS Service Options - $($Vserver)"
                    List = $true
                    ColumnWidths = 50, 50
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $VserverObj | Table @TableParams
            }
        } catch {
            Write-PScriboMessage -IsWarning $_.Exception.Message
        }
    }

    end {}

}