function Get-AbrOntapSysConfigImage {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP System Image information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.3.0
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
        Write-PscriboMessage "Collecting ONTAP System Image information."
    }

    process {
        $Data =  Get-NcSystemImage
        $OutObj = @()
        if ($Data) {
            foreach ($Item in $Data) {
                $inObj = [ordered] @{
                    'Node' = $Item.Node
                    'Location' = $Item.Image
                    'Is Current' = Switch ($Item.IsCurrent) {
                        'True' { 'Yes' }
                        'False' { 'No' }
                    }
                    'Is Default' = Switch ($Item.IsDefault) {
                        'True' { 'Yes' }
                        'False' { 'No' }
                    }
                    'Install Time' = $Item.InstallTimeDT
                    'Version' = $Item.Version
                }
                $OutObj += [pscustomobject]$inobj
            }

            $TableParams = @{
                Name = "System Image information - $($ClusterInfo.ClusterName)"
                List = $false
                ColumnWidths = 23, 15, 12, 12, 26, 12
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $OutObj | Table @TableParams
        }
    }

    end {}

}