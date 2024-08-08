function Get-AbrOntapVserverCIFSSecurity {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP Vserver CIFS Security information from the Cluster Management Network
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
        Write-PScriboMessage "Collecting ONTAP Vserver CIFS Security information."
    }

    process {
        try {
            $VserverData = Get-NcVserver -VserverContext $Vserver -Controller $Array | Where-Object { $_.VserverType -eq 'data' -and $_.AllowedProtocols -eq 'cifs' -and $_.State -eq 'running' }
            $VserverObj = @()
            if ($VserverData) {
                foreach ($Item in $VserverData) {
                    try {
                        $CIFSSVM = Get-NcCifsSecurity -VserverContext $Item.Vserver -Controller $Array
                        foreach ($SVM in $CIFSSVM) {
                            if ($SVM.KerberosClockSkew) {
                                $inObj = [ordered] @{
                                    'Kerberos Clock Skew' = $SVM.KerberosClockSkew
                                    'Kerberos Renew Age' = $SVM.KerberosRenewAge
                                    'Kerberos Ticket Age' = $SVM.KerberosTicketAge
                                    'Aes Encryption Enabled' = ConvertTo-TextYN $SVM.IsAesEncryptionEnabled
                                    'Signing Required' = ConvertTo-TextYN $SVM.IsSigningRequired
                                    'Smb Encryption Required' = ConvertTo-TextYN $SVM.IsSmbEncryptionRequired
                                    'Lm Compatibility Level' = $SVM.LmCompatibilityLevel
                                }
                                $VserverObj += [pscustomobject]$inobj
                            } else { continue }
                        }
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }

                $TableParams = @{
                    Name = "CIFS Service Security - $($Vserver)"
                    List = $true
                    ColumnWidths = 35, 65
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