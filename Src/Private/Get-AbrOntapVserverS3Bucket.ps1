function Get-AbrOntapVserverS3Bucket {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP Vserver S3 bucket information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.6.7
        Author:         Jonathan Colon
        Twitter:        @jcolonfzenpr
        Github:         rebelinux
    .EXAMPLE

    .LINK

    #>
    param (
        [Parameter (
            Position = 0,
            Mandatory)]
        [string]
        $Vserver
    )

    begin {
        Write-PScriboMessage "Collecting ONTAP Vserver S3 bucket information."
    }

    process {
        try {
            $VserverData = Get-NetAppOntapAPI -uri "/api/protocols/s3/buckets?svm=$Vserver&fields=*&return_records=true&return_timeout=15"
            $VserverObj = @()
            if ($VserverData) {
                foreach ($Item in $VserverData) {
                    try {
                        $inObj = [ordered] @{
                            'Bucket' = $Item.Name
                            'Volume' = $Item.volume.name
                            'Total' = $Item.size | ConvertTo-FormattedNumber -Type Datasize -ErrorAction SilentlyContinue
                            'Used' = $Item.logical_used_size | ConvertTo-FormattedNumber -Type Datasize -ErrorAction SilentlyContinue
                        }
                        $VserverObj += [pscustomobject]$inobj
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }

                $TableParams = @{
                    Name = "S3 Bucket - $($Vserver)"
                    List = $false
                    ColumnWidths = 30, 30, 20, 20
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $VserverObj | Table @TableParams
            }
        } catch {
            Write-PScriboMessage -IsWarning $_.Exception.Message
        }
    }

    end {}

}