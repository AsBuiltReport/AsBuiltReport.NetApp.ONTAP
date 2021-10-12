function Get-AbrOntapVserverCIFSLocalGroup {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP Vserver CIFS Local Group information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.5.0
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
        Write-PscriboMessage "Collecting ONTAP CIFS Local Group information."
    }

    process {
        $VserverData = Get-NcCifsLocalGroup -VserverContext $Vserver -Controller $Array
        $VserverObj = @()
        if ($VserverData) {
            foreach ($Item in $VserverData) {
                $inObj = [ordered] @{
                    'Group Name' = $Item.GroupName
                    'Description' = $Item.Description
                }
                $VserverObj += [pscustomobject]$inobj
            }

            $TableParams = @{
                Name = "CIFS Connected Local Group Information - $($Vserver)"
                List = $false
                ColumnWidths = 50, 50
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $VserverObj | Table @TableParams
        }
    }

    end {}

}