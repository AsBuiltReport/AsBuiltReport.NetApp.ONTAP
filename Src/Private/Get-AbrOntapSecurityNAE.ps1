function Get-AbrOntapSecurityNAE {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP Security Aggregate NAE information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.4.0
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
        Write-PscriboMessage "Collecting ONTAP Security Aggregate NAE information."
    }

    process {
        $Data =  Get-NcAggr -Controller $Array
        $OutObj = @()
        if ($Data) {
            foreach ($Item in $Data) {
                $NAE = (Get-NcAggrOption -Name $Item.Name -Controller $Array | Where-Object {$_.Name -eq "encrypt_with_aggr_key"}).Value
                $inObj = [ordered] @{
                    'Aggregate' = $Item.Name
                    'Aggregate Encryption' = Switch ($NAE) {
                        'true' { 'Yes' }
                        'false' { 'No' }
                        $Null { 'Unsupported' }
                        default { $NAE }
                    }
                    'Volume Count' = $Item.Volumes
                    'State' = $TextInfo.ToTitleCase($Item.State)
                }
                $OutObj += [pscustomobject]$inobj
            }
            if ($Healthcheck.Storage.Aggr) {
                $OutObj | Where-Object { $_.'State' -ne 'Online'} | Set-Style -Style Warning -Property 'State'
            }

            $TableParams = @{
                Name = "Aggregate Encryption (NAE) information  - $($ClusterInfo.ClusterName)"
                List = $false
                ColumnWidths = 45, 27, 15, 13
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $OutObj | Table @TableParams
        }
    }

    end {}

}