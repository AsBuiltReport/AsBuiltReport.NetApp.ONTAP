function Get-AbrOntapSecurityNVE {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP Security Volume NVE information from the Cluster Management Network
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
        Write-PScriboMessage "Collecting ONTAP Security Volume NVE information."
    }

    process {
        try {
            $Data = Get-NcVol -Controller $Array | Where-Object { $_.JunctionPath -ne '/' -and $_.Name -ne 'vol0' -and $_.VolumeStateAttributes.IsConstituent -ne "True" }  | Select-Object -Property vserver, name, aggregate, state, @{Label = "Node"; expression = { $_.VolumeIdAttributes.Nodes } }, encrypt, @{Label = "encryptionstate"; expression = { (Get-NcVolumeEncryptionConversion -Vserver $_.vserver -Volume $_.name -Controller $Array).status } }
            $OutObj = @()
            if ($Data) {
                foreach ($Item in $Data) {
                    try {
                        $inObj = [ordered] @{
                            'Name' = $Item.Name
                            'Aggregate' = $Item.Aggregate
                            'Encrypted' = ConvertTo-TextYN $Item.Encrypt
                            'State' = $TextInfo.ToTitleCase($Item.State)
                        }
                        $OutObj += [pscustomobject]$inobj
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }
                if ($Healthcheck.Storage.Aggr) {
                    $OutObj | Where-Object { $_.'State' -ne 'Online' } | Set-Style -Style Warning -Property 'State'
                }

                $TableParams = @{
                    Name = "Volume Encryption (NVE) - $($ClusterInfo.ClusterName)"
                    List = $false
                    ColumnWidths = 45, 35, 11, 9
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