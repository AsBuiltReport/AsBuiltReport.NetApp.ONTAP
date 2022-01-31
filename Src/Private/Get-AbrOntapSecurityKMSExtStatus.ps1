function Get-AbrOntapSecurityKMSExtStatus {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP Security Key Management Service External Status information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.6.3
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
        Write-PscriboMessage "Collecting ONTAP Security Key Management Service External Status information."
    }

    process {
        try {
            $Data = Get-NcSecurityKeyManager -Controller $Array
            $OutObj = @()
            if ($Data) {
                foreach ($Item in $Data) {
                    try {
                        $inObj = [ordered] @{
                            'Node' = $Item.NodeName
                            'Key Manager IP' = $Item.KeyManagerIpAddress
                            'Key Manager Port' = $Item.KeyManagerTcpPort
                            'Status' = $TextInfo.ToTitleCase($Item.KeyManagerServerStatus)
                        }
                        $OutObj += [pscustomobject]$inobj
                    }
                    catch {
                        Write-PscriboMessage -IsWarning $_.Exception.Message
                    }
                }

                if ($Healthcheck.Security.KMS) {
                    $OutObj | Where-Object { $_.'Status' -ne 'Available'} | Set-Style -Style Critical -Property 'Status'
                }

                $TableParams = @{
                    Name = "External Key Management Service (KMS) Status - $($ClusterInfo.ClusterName)"
                    List = $false
                    ColumnWidths = 35, 25, 15, 25
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $OutObj | Table @TableParams
            }
        }
        catch {
            Write-PscriboMessage -IsWarning $_.Exception.Message
        }
    }

    end {}

}