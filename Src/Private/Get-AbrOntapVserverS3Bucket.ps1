function Get-AbrOntapVserverS3Bucket {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP Vserver S3 bucket information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.1.0
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
        Write-PscriboMessage "Collecting ONTAP Vserver S3 bucket information."
    }

    process {
        $VserverData = Get-AbrOntapApi -uri "/api/protocols/s3/buckets?"
        $VserverObj = @()
        if ($VserverData) {
            foreach ($Item in $VserverData) {
                $inObj = [ordered] @{
                    'Bucket' = $Item.Name
                    'Volume' = $Item.volume.name
                    'Total' = "$([math]::Round(($Item.size) / "1Gb", 0)) GB" #// TODO convert to ConvertTo-FormattedNumber
                    'Used' = "$([math]::Round(($Item.logical_used_size) / "1Gb", 0)) GB" #// TODO convert to ConvertTo-FormattedNumber
                    'Vserver' = $Item.svm.name
                }
                $VserverObj += [pscustomobject]$inobj
            }

            $TableParams = @{
                Name = "Vserver S3 Bucket Information - $($ClusterInfo.ClusterName)"
                List = $false
                ColumnWidths = 30, 25, 15, 15, 15
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $VserverObj | Table @TableParams
        }
    }

    end {}

}