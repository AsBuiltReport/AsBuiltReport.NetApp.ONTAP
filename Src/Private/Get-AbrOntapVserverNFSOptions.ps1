function Get-AbrOntapVserverNFSOption {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP Vserver NFS Options information from the Cluster Management Network
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
        $Vserver
    )

    begin {
        Write-PScriboMessage "Collecting ONTAP Vserver NFS Option information."
    }

    process {
        try {
            $VserverData = Get-NcNfsService -VserverContext $Vserver -Controller $Array
            $VserverObj = @()
            if ($VserverData) {
                foreach ($Item in $VserverData) {
                    try {
                        $inObj = [ordered] @{
                            'Allow Idle Connection' = ConvertTo-TextYN $Item.AllowIdleConnection
                            'Idle Connection Timeout' = $Item.IdleConnectionTimeout
                            'Ignore NtAcl For Root' = ConvertTo-TextYN $Item.IgnoreNtAclForRoot
                            'Enable Ejukebox' = ConvertTo-TextYN $Item.EnableEjukebox
                            'Nfs Access Enabled' = ConvertTo-TextYN $Item.IsNfsAccessEnabled
                            'Nfs Rootonly Enabled' = ConvertTo-TextYN $Item.IsNfsRootonlyEnabled
                            'Nfsv2 Enabled' = ConvertTo-TextYN $Item.IsNfsv2Enabled
                            'Nfsv3 Enabled' = ConvertTo-TextYN $Item.IsNfsv3Enabled
                            'Nfsv3 64bit Identifiers Enabled' = ConvertTo-TextYN $Item.IsNfsv364bitIdentifiersEnabled
                            'Nfsv3 Connection Drop Enabled' = ConvertTo-TextYN $Item.IsNfsv3ConnectionDropEnabled
                            'Nfsv3 Fsid Change Enabled' = ConvertTo-TextYN $Item.IsNfsv3FsidChangeEnabled
                            'Nfsv40 Acl Enabled' = ConvertTo-TextYN $Item.IsNfsv40AclEnabled
                            'Nfsv40 Enabled' = ConvertTo-TextYN $Item.IsNfsv40Enabled
                        }
                        $VserverObj += [pscustomobject]$inobj
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