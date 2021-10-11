function Get-AbrOntapVserverIscsiInitiator {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP Vserver ISCSI ClientInitiators information from the Cluster Management Network
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
        Write-PscriboMessage "Collecting ONTAP Vserver ISCSI Client Initiators information."
    }

    process {
        $VserverData = Get-NcIscsiInitiator -VserverContext $Vserver
        $VserverObj = @()
        if ($VserverData) {
            foreach ($Item in $VserverData) {
                $inObj = [ordered] @{
                    'Initiator Name' = $Item.InitiatorNodeName
                    'Target Port Group' = $Item.TpGroupName
                }
                $VserverObj += [pscustomobject]$inobj
            }

            $TableParams = @{
                Name = "ISCSI Client Initiator Information - $($Vserver)"
                List = $false
                ColumnWidths = 60, 40
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $VserverObj | Table @TableParams
        }
    }

    end {}

}