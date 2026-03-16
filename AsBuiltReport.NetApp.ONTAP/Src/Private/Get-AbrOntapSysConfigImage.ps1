function Get-AbrOntapSysConfigImage {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP System Image information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.6.12
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
        Write-PScriboMessage 'Collecting ONTAP System Image information.'
    }

    process {
        try {
            $Data = Get-NcSystemImage -Controller $Array
            $OutObj = @()
            if ($Data) {
                foreach ($Item in $Data) {
                    try {
                        $inObj = [ordered] @{
                            'Node' = $Item.Node
                            'Location' = $Item.Image
                            'Is Current' = $Item.IsCurrent
                            'Is Default' = $Item.IsDefault
                            'Install Time' = $Item.InstallTimeDT
                            'Version' = $Item.Version
                        }
                        $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }

                $TableParams = @{
                    Name = "System Image - $($ClusterInfo.ClusterName)"
                    List = $false
                    ColumnWidths = 23, 15, 12, 12, 26, 12
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $OutObj | Table @TableParams
            }
        } catch {
            Write-PScriboMessage -IsWarning $_.Exception.Message
        }
    }

    end {}

}