function Get-AbrOntapVserverVolumesExportPolicy {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP vserver volumes export policy information from the Cluster Management Network
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
        Write-PScriboMessage "Collecting ONTAP Vserver volumes export policy information."
    }

    process {
        try {
            $VserverData = Get-NcExportRule -VserverContext $Vserver -Controller $Array
            $VserverObj = @()
            if ($VserverData) {
                foreach ($Item in $VserverData) {
                    try {
                        $inObj = [ordered] @{
                            'Policy Name' = $Item.PolicyName
                            'Rule Index' = $Item.RuleIndex
                            'Client Match' = $Item.ClientMatch
                            'Protocol' = $Item.Protocol -join ", "
                            'Ro Rule' = $Item.RoRule
                            'Rw Rule' = $Item.RwRule
                        }
                        $VserverObj += [pscustomobject]$inobj
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }

                $TableParams = @{
                    Name = "Volume Export Policy - $($Vserver)"
                    List = $false
                    ColumnWidths = 20, 15, 20, 15, 15, 15
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