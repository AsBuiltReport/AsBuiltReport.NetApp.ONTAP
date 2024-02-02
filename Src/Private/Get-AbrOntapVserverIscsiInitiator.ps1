function Get-AbrOntapVserverIscsiInitiator {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP Vserver ISCSI ClientInitiators information from the Cluster Management Network
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
        Write-PScriboMessage "Collecting ONTAP Vserver ISCSI Client Initiators information."
    }

    process {
        try {
            $VserverData = Get-NcIscsiInitiator -VserverContext $Vserver -Controller $Array
            $VserverObj = @()
            if ($VserverData) {
                foreach ($Item in $VserverData) {
                    try {
                        $inObj = [ordered] @{
                            'Initiator Name' = $Item.InitiatorNodeName
                            'Target Port Group' = $Item.TpGroupName
                        }
                        $VserverObj += [pscustomobject]$inobj
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }

                $TableParams = @{
                    Name = "ISCSI Client Initiator - $($Vserver)"
                    List = $false
                    ColumnWidths = 60, 40
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