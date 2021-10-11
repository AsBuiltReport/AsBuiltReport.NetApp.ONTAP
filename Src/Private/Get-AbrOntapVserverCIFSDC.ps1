function Get-AbrOntapVserverCIFSDC {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP Vserver CIFS Domain Controller Properties information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.4.0
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
        Write-PscriboMessage "Collecting ONTAP CIFS Domain Controller Properties information."
    }

    process {
        $VserverData = Get-NcCifsDomainServer -VserverContext $Vserver
        $VserverObj = @()
        if ($VserverData) {
            foreach ($Item in $VserverData) {
                $inObj = [ordered] @{
                    'DC Name' = $Item.Name
                    'Domain' = $Item.Domain
                    'Node' = $Item.Node
                    'Server Type' = $Item.ServerType
                    'Prefer Type' = $Item.PreferType
                    'Status' = $Item.Status
                }
                $VserverObj += [pscustomobject]$inobj
            }

            $TableParams = @{
                Name = "CIFS Connected Domain Controller Information - $($Vserver)"
                List = $false
                ColumnWidths = 20, 20, 20, 12, 13, 15
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $VserverObj | Table @TableParams
        }
    }

    end {}

}