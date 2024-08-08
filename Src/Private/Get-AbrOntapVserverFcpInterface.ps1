function Get-AbrOntapVserverFcpInterface {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP Vserver FCP interface information from the Cluster Management Network
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
        Write-PScriboMessage "Collecting ONTAP Vserver FCP interface information."
    }

    process {
        try {
            $VserverData = Get-NcFcpInterface -VserverContext $Vserver -Controller $Array
            $VserverObj = @()
            if ($VserverData) {
                foreach ($Item in $VserverData) {
                    try {
                        $inObj = [ordered] @{
                            'Interface Name' = $Item.InterfaceName
                            'FCP WWPN' = $Item.PortName
                            'Home Port' = $Item.CurrentPort
                        }
                        $VserverObj += [pscustomobject]$inobj
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }

                $TableParams = @{
                    Name = "FCP Interface - $($Vserver)"
                    List = $false
                    ColumnWidths = 35, 35, 30
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