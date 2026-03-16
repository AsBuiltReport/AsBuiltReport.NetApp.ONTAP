function Get-AbrOntapVserverCGSummary {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP Vserver Consistency Groups information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.6.12
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
        Write-PScriboMessage 'Collecting ONTAP Vserver Consistency Groups information.'
    }

    process {
        try {
            $VserverData = Get-NetAppOntapAPI -uri "/api/application/consistency-groups?svm=$Vserver&fields=**&return_records=true&return_timeout=15"
            $VserverObj = @()
            if ($VserverData) {
                foreach ($Item in $VserverData) {
                    try {
                        $inObj = [ordered] @{
                            'Name' = $Item.Name
                            'Capacity' = ($Item.space.size | ConvertTo-FormattedNumber -ErrorAction SilentlyContinue -NumberFormatString 0.0 -Type Datasize) ?? '--'
                            'Available' = ($Item.space.available | ConvertTo-FormattedNumber -ErrorAction SilentlyContinue -NumberFormatString 0.0 -Type Datasize) ?? '--'
                            'Used' = ($Item.space.used | ConvertTo-FormattedNumber -ErrorAction SilentlyContinue -NumberFormatString 0.0 -Type Datasize) ?? '--'
                            'Replicated' = $Item.replicated
                            'Lun Count' = ($Item.luns.name).count
                        }
                        $VserverObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }

                $TableParams = @{
                    Name = "Consistency Groups - $($Vserver)"
                    List = $false
                    ColumnWidths = 40, 12, 12, 12, 12, 12
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