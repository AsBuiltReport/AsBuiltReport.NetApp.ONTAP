function Get-AbrOntapVserverS3Bucket {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP Vserver S3 bucket information from the Cluster Management Network
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
        Write-PscriboMessage "Collecting ONTAP Vserver S3 bucket information."
    }

    process {
        $VserverData = Get-NetAppOntapAPI -uri "/api/protocols/s3/buckets?"
        $VserverObj = @()
        if ($VserverData) {
            foreach ($Item in $VserverData) {
                $inObj = [ordered] @{
                    'Bucket' = $Item.Name
                    'Volume' = $Item.volume.name
                    'Total' = $Item.size | ConvertTo-FormattedNumber -Type Datasize -ErrorAction SilentlyContinue
                    'Used' = $Item.logical_used_size | ConvertTo-FormattedNumber -Type Datasize -ErrorAction SilentlyContinue
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