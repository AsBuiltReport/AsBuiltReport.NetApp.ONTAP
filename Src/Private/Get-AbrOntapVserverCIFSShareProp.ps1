function Get-AbrOntapVserverCIFSShareProp {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP Vserver CIFS Share Properties information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.6.3
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
        Write-PscriboMessage "Collecting ONTAP CIFS Share Properties information."
    }

    process {
        try {
            $VserverData = Get-NcCifsShare -VserverContext $Vserver -Controller $Array
            $VserverObj = @()
            if ($VserverData) {
                foreach ($Item in $VserverData) {
                    try {
                        $inObj = [ordered] @{
                            'Share Name' = $Item.ShareName
                            'Share ACL' = $Item.Acl
                            'Share Properties' = ($Item).ShareProperties -join ', '
                        }
                        $VserverObj += [pscustomobject]$inobj
                    }
                    catch {
                        Write-PscriboMessage -IsWarning $_.Exception.Message
                    }
                }

                $TableParams = @{
                    Name = "The CIFS Share Properties & Acl - $($Vserver)"
                    List = $false
                    ColumnWidths = 30, 35, 35
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $VserverObj | Table @TableParams
            }
        }
        catch {
            Write-PscriboMessage -IsWarning $_.Exception.Message
        }
    }

    end {}

}