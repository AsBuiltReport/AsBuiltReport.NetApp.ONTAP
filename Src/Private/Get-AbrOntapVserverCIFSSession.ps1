function Get-AbrOntapVserverCIFSSession {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP Vserver CIFS Sessions information from the Cluster Management Network
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
        Write-PScriboMessage "Collecting ONTAP CIFS Session information."
    }

    process {
        try {
            $VserverData = Get-NcCifsSession -VserverContext $Vserver -Controller $Array
            $VserverObj = @()
            if ($VserverData) {
                foreach ($Item in $VserverData) {
                    try {
                        $inObj = [ordered] @{
                            'Lif Address' = $Item.LifAddress
                            'Connected Time' = $Item.ConnectedTime
                            'Protocol Version' = $Item.ProtocolVersion
                            'Address' = $Item.Address
                            'User' = $Item.WindowsUser
                        }
                        $VserverObj += [pscustomobject]$inobj
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }

                $TableParams = @{
                    Name = "CIFS Sessions - $($Vserver)"
                    List = $false
                    ColumnWidths = 20, 15, 15, 20, 30
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