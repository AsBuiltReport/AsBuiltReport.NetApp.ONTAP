function Get-AbrOntapVserverCIFSOption {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP Vserver CIFS Options information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.5.0
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
        Write-PscriboMessage "Collecting ONTAP Vserver CIFS Option information."
    }

    process {
        $VserverData = Get-NcVserver -VserverContext $Vserver -Controller $Array | Where-Object { $_.VserverType -eq 'data' -and $_.AllowedProtocols -eq 'cifs' -and $_.State -eq 'running' }
        $VserverObj = @()
        if ($VserverData) {
            foreach ($SVM in $VserverData) {
                $CIFSSVM = Get-NcCifsOption -VserverContext $SVM.Vserver -Controller $Array
                foreach ($Item in $CIFSSVM) {
                    $inObj = [ordered] @{
                        'Client Session Timeout' = $Item.ClientSessionTimeout
                        'Default Unix User' = $Item.DefaultUnixUser
                        'Client Version Reporting Enabled' = ConvertTo-TextYN $Item.IsClientVersionReportingEnabled
                        'Copy Offload Direct Copy Enabled' = ConvertTo-TextYN $Item.IsCopyOffloadDirectCopyEnabled
                        'Copy Offload Enabled' = ConvertTo-TextYN $Item.IsCopyOffloadEnabled
                        'Dac Enabled' = ConvertTo-TextYN $Item.IsDacEnabled
                        'Export Policy Enabled' = ConvertTo-TextYN $Item.IsExportpolicyEnabled
                        'Large MTU Enabled' = ConvertTo-TextYN $Item.IsLargeMtuEnabled
                        'Local Auth Enabled' = ConvertTo-TextYN $Item.IsLocalAuthEnabled
                        'Local Users And Groups Enabled' = ConvertTo-TextYN $Item.IsLocalUsersAndGroupsEnabled
                        'Multi Channel Enabled' = ConvertTo-TextYN $Item.IsMultichannelEnabled
                        'Nbns Enabled' = ConvertTo-TextYN $Item.IsNbnsEnabled
                        'Netbios Over Tcp Enabled' = ConvertTo-TextYN $Item.IsNetbiosOverTcpEnabled
                        'Referral Enabled' = ConvertTo-TextYN $Item.IsReferralEnabled
                        'Shadow Copy Enabled' = ConvertTo-TextYN $Item.IsShadowcopyEnabled
                        'Smb1 Enabled' = ConvertTo-TextYN $Item.IsSmb1Enabled
                        'Smb2 Enabled' = ConvertTo-TextYN $Item.IsSmb2Enabled
                        'Smb31 Enabled' = ConvertTo-TextYN $Item.IsSmb31Enabled
                        'Smb3 Enabled' = ConvertTo-TextYN $Item.IsSmb3Enabled
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
                Name = "Vserver CIFS Service Options - $($Vserver)"
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