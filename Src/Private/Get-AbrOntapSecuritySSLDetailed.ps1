function Get-AbrOntapSecuritySSLDetailed {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP Security Vserver SSL Detailed information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.6.7
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
        Write-PScriboMessage "Collecting ONTAP Security Vserver SSL Detailed information."
    }

    process {
        try {
            $Data = Get-NcSecurityCertificate -Controller $Array | Where-Object { $_.Type -eq "server" -and $_.Vserver -notin $Options.Exclude.Vserver }
            $OutObj = @()
            if ($Data) {
                foreach ($Item in $Data) {
                    try {
                        $inObj = [ordered] @{
                            'Common Name' = $Item.CommonName
                            'Protocol' = $Item.Protocol
                            'Hash Function' = $Item.HashFunction
                            'Serial Number' = $Item.SerialNumber
                            'Expiration' = Switch ([string]::IsNullOrEmpty($Item.ExpirationDateDT)) {
                                $true { '-' }
                                $false { ($Item.ExpirationDateDT).ToString().Split(" ")[0] }
                                default { 'Unknown' }
                            }
                            'Vserver' = $Item.Vserver
                        }
                        $OutObj += [pscustomobject]$inobj
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }

                $TableParams = @{
                    Name = "SSL Detailed - $($ClusterInfo.ClusterName)"
                    List = $false
                    ColumnWidths = 18, 10, 10, 25, 19, 18
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $OutObj | Table @TableParams
            }
        } catch {
            Write-PScriboMessage -IsWarning $_.Exception.Message
        }
    }

    end {}

}