function Get-AbrOntapVserverVolumesExportPolicy {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP vserver volumes export policy information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.1.0
        Author:         Jonathan Colon
        Twitter:        @jcolonfzenpr
        Github:         rebelinux
    .EXAMPLE

    .LINK

    #>
    [CmdletBinding()]
    param (
    )

    begin {
        Write-PscriboMessage "Collecting ONTAP Vserver volumes export policy information."
    }

    process {
        $VserverData = Get-NcExportRule
        $VserverObj = @()
        if ($VserverData) {
            foreach ($Item in $VserverData) {
                $inObj = [ordered] @{
                    'Policy Name' = $Item.PolicyName
                    'Rule Index' = $Item.RuleIndex
                    'Client Match' = $Item.ClientMatch
                    'Protocol' = $Item.Protocol
                    'Ro Rule' = $Item.RoRule
                    'Rw Rule' = $Item.RwRule
                    'Vserver' = $Item.Vserver
                }
                $VserverObj += [pscustomobject]$inobj
            }

            $TableParams = @{
                Name = "Vserver Volume Export Policy Information - $($ClusterInfo.ClusterName)"
                List = $false
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $VserverObj | Table @TableParams
        }
    }

    end {}

}