function Get-AbrOntapVserverFcpInterface {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP Vserver FCP interface information from the Cluster Management Network
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
        Write-PScriboMessage 'Collecting ONTAP Vserver FCP interface information.'
    }

    process {
        try {
            $VserverData = Get-NcFcpInterface -VserverContext $Vserver -Controller $Array | Sort-Object -Property CurrentNode
            $VserverObj = @()
            if ($VserverData) {
                foreach ($Item in $VserverData) {
                    try {
                        $inObj = [ordered] @{
                            'Interface Name' = $Item.InterfaceName
                            'FCP WWPN' = $Item.PortName
                            'Node Name' = $Item.CurrentNode
                            'Home Port' = $Item.CurrentPort
                        }
                        $VserverObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }

                $TableParams = @{
                    Name = "FCP Interface - $($Vserver)"
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