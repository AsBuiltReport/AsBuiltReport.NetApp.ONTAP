function Get-AbrOntapStorageFabricPool {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP Aggregate FabriPool information from the Cluster Management Network
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
        Write-PscriboMessage "Collecting ONTAP Aggregate FabriPool information."
    }

    process {
        $Data =  Get-NcAggrObjectStore
        $OutObj = @()
        if ($Data) {
            foreach ($Item in $Data) {

                $inObj = [ordered] @{
                    'Aggregate' = $Item.Aggregate
                    'Fabric Pool Name' = $Item.ObjectStoreName
                    'Type' = $Item.ProviderType
                    'Used Space' = $Item.UsedSpace | ConvertTo-FormattedNumber -Type Datasize -NumberFormatString "0.0" -ErrorAction SilentlyContinue
                    'Status' = $Item.ObjectStoreAvailability
                }
                $OutObj += [pscustomobject]$inobj
            }
            if ($Healthcheck.Storage.FabricPool) {
                $OutObj | Where-Object { $_.'Status' -like 'unavailable' } | Set-Style -Style Warning -Property 'Status'
            }

            $TableParams = @{
                Name = "Aggregate FabriPool Information - $($ClusterInfo.ClusterName)"
                List = $false
                ColumnWidths = 30, 20, 20, 15, 15
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $OutObj | Table @TableParams
        }
    }

    end {}

}