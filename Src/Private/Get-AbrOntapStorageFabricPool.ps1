function Get-AbrOntapStorageFabricPool {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP Aggregate FabriPool information from the Cluster Management Network
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
        Write-PScriboMessage "Collecting ONTAP Aggregate FabriPool information."
    }

    process {
        try {
            $Data = Get-NcAggrObjectStore -Controller $Array
            $OutObj = @()
            if ($Data) {
                foreach ($Item in $Data) {
                    try {

                        $inObj = [ordered] @{
                            'Aggregate' = $Item.Aggregate
                            'Fabric Pool Name' = $Item.ObjectStoreName
                            'Type' = $Item.ProviderType
                            'Used Space' = $Item.UsedSpace | ConvertTo-FormattedNumber -Type Datasize -NumberFormatString "0.0" -ErrorAction SilentlyContinue
                            'Status' = $Item.ObjectStoreAvailability
                        }
                        $OutObj += [pscustomobject]$inobj
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }
                if ($Healthcheck.Storage.FabricPool) {
                    $OutObj | Where-Object { $_.'Status' -like 'unavailable' } | Set-Style -Style Warning -Property 'Status'
                }

                $TableParams = @{
                    Name = "Aggregate FabriPool - $($ClusterInfo.ClusterName)"
                    List = $false
                    ColumnWidths = 30, 20, 20, 15, 15
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