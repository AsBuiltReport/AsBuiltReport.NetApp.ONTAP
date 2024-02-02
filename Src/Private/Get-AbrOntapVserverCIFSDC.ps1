function Get-AbrOntapVserverCIFSDC {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP Vserver CIFS Domain Controller Properties information from the Cluster Management Network
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
        Write-PScriboMessage "Collecting ONTAP CIFS Domain Controller Properties information."
    }

    process {
        try {
            $VserverData = Get-NcCifsDomainServer -VserverContext $Vserver -Controller $Array
            $VserverObj = @()
            if ($VserverData) {
                foreach ($Item in $VserverData) {
                    try {
                        $inObj = [ordered] @{
                            'DC Name' = $Item.Name
                            'Domain' = $Item.Domain
                            'Node' = $Item.Node
                            'Server Type' = $Item.ServerType
                            'Prefer Type' = $Item.PreferType
                            'Status' = $Item.Status
                        }
                        $VserverObj += [pscustomobject]$inobj
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }

                $TableParams = @{
                    Name = "CIFS Connected Domain Controller - $($Vserver)"
                    List = $false
                    ColumnWidths = 20, 20, 20, 12, 13, 15
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