function Get-AbrOntapVserverNetworkInterface {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP vserver interfaces information
    .DESCRIPTION

    .NOTES
        Version:        0.6.12
        Author:         Jonathan Colon
        Twitter:        @jcolonfzenpr
        Github:         rebelinux
    .EXAMPLE

    .LINK

    #>
    [CmdletBinding()]
    param (
        [Parameter (
            Position = 0,
            Mandatory)]
        [string]
        $Vserver
    )

    begin {
        Write-PScriboMessage 'Collecting ONTAP vserver network interface information.'
    }

    process {
        try {
            $ClusterData = Get-NcNetInterface -Controller $Array | Where-Object { $_.Role -eq 'data' -and $_.Vserver -notin $options.Exclude.Vserver -and $_.Vserver -eq $Vserver }
            $ClusterObj = @()
            if ($ClusterData) {
                foreach ($Item in $ClusterData) {
                    try {
                        $inObj = [ordered] @{
                            'Data Interface' = $Item.InterfaceName
                            'Status' = ${Item}?.OpStatus?.ToString()?.ToUpper()
                            'Data Protocols' = [string]$Item.DataProtocols
                            'Address' = ($Null -eq $Item.Wwpn) ? $Item.Address: $Item.Wwpn
                            'Is Home' = $Item.IsHome
                        }
                        $ClusterObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }
                if ($Healthcheck.Network.Interface) {
                    $ClusterObj | Where-Object { $_.'Status' -notlike 'UP' } | Set-Style -Style Warning -Property 'Status'
                }

                $TableParams = @{
                    Name = "Data Network - $($Vserver)"
                    List = $false
                    ColumnWidths = 33, 10, 21, 18, 18
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $ClusterObj | Table @TableParams
                if ($Healthcheck.Network.Interface -and ($ClusterObj | Where-Object { $_.'Status' -notlike 'UP' })) {
                    Paragraph 'Health Check:' -Bold -Underline
                    BlankLine
                    Paragraph {
                        Text 'Best Practice:' -Bold
                        Text 'Ensure that all data network interfaces are operational (UP) to maintain optimal data access and performance.'
                    }
                    BlankLine
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning $_.Exception.Message
        }
    }

    end {}

}