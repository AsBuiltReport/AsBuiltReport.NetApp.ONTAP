function Get-AbrOntapEfficiencyAggrConfig {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP Aggregate FabriPool Object Store Configuration from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.3.0
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
        Write-PscriboMessage "Collecting ONTAP Aggregate FabriPool Object Store information."
    }

    process {
        $Data =  Get-NcAggrObjectStoreConfig
        $OutObj = @()
        if ($Data) {
            foreach ($Item in $Data) {
                $inObj = [ordered] @{
                    'Object Store Name' = $Item.ObjectStoreName
                    'S3 Name' = $Item.S3Name
                    'Server FQDN' = $Item.Server
                    'Port' = $Item.Port
                    'SSL Enabled' = $Item.SslEnabled
                    'Provider Type' = $Item.ProviderType
                    'Used Space' = $Item.UsedSpace | ConvertTo-FormattedNumber -Type Datasize -NumberFormatString "0.0" -ErrorAction SilentlyContinue
                }
                $OutObj += [pscustomobject]$inobj
            }

            $TableParams = @{
                Name = "Aggregate FabriPool Object Store Configuration - $($ClusterInfo.ClusterName)"
                List = $true
                ColumnWidths = 30, 70
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $OutObj | Table @TableParams
        }
    }

    end {}

}