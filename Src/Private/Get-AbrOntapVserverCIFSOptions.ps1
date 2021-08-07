function Get-AbrOntapVserverCIFSOptions {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP Vserver CIFS Options information from the Cluster Management Network
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
        Write-PscriboMessage "Collecting ONTAP Vserver CIFS Option information."
    }

    process {
        $VserverData = Get-NcVserver | Where-Object { $_.VserverType -eq 'data' -and $_.AllowedProtocols -eq 'cifs' -and $_.State -eq 'running' }
        $VserverObj = @()
        if ($VserverData) {
            foreach ($SVM in $VserverData) {
                $CIFSSVM = Get-NcCifsOption -VserverContext $SVM.Vserver
                foreach ($Item in $CIFSSVM) {
                    $inObj = [ordered] @{
                        'Vserver' = $Item.Vserver
                        'Client Session Timeout' = $Item.ClientSessionTimeout
                        'DefaultUnixUser' = $Item.DefaultUnixUser
                        'Client Version Reporting Enabled' = $Item.IsClientVersionReportingEnabled
                        'Copy Offload Direct Copy Enabled' = $Item.IsCopyOffloadDirectCopyEnabled
                        'Copy Offload Enabled' = $Item.IsCopyOffloadEnabled
                        'Dac Enabled' = $Item.IsDacEnabled
                        'Export Policy Enabled' = $Item.IsExportpolicyEnabled
                        'Large Mtu Enabled' = $Item.IsLargeMtuEnabled
                        'Local Auth Enabled' = $Item.IsLocalAuthEnabled
                        'Local Users And Groups Enabled' = $Item.IsLocalUsersAndGroupsEnabled
                        'Multi Channel Enabled' = $Item.IsMultichannelEnabled
                        'Nbns Enabled' = $Item.IsNbnsEnabled
                        'Netbios Over Tcp Enabled' = $Item.IsNetbiosOverTcpEnabled
                        'Referral Enabled' = $Item.IsReferralEnabled
                        'Shadow Copy Enabled' = $Item.IsShadowcopyEnabled
                        'Smb1 Enabled' = $Item.IsSmb1Enabled
                        'Smb2 Enabled' = $Item.IsSmb2Enabled
                        'Smb31 Enabled' = $Item.IsSmb31Enabled
                        'Smb3 Enabled' = $Item.IsSmb3Enabled
                        'Max Connections Per Session' = $Item.MaxConnectionsPerSession
                        'Max Credits' = $Item.MaxCredits
                        'Max File Write Zero Length' = $Item.MaxFileWriteZeroLength
                        'Max Lifs Per Session' = $Item.MaxLifsPerSession
                        'Max Mpx' = $Item.MaxMpx
                        'Max Opens Same File Per Tree' = $Item.MaxOpensSameFilePerTree
                        'Restrict Anonymous' = $Item.RestrictAnonymous
                        'Shadow Copy Dir Depth' = $Item.ShadowcopyDirDepth
                        'Smb1 Max Buffer Size' = $Item.Smb1MaxBufferSize
                    }
                    $VserverObj += [pscustomobject]$inobj
                }
            }

            $TableParams = @{
                Name = "Vserver CIFS Service Options Summary - $($ClusterInfo.ClusterName)"
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