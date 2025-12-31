function Get-AbrOntapDiskOwner {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP disk assign summary information from the Cluster Management Network
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
        [Parameter (
            Position = 0,
            Mandatory)]
        [string]
        $Node
    )

    begin {
        Write-PScriboMessage 'Collecting ONTAP disk owned per node information.'
    }

    process {
        try {
            if ($Node) {
                $OutObj = @()
                foreach ($Owner in $Node) {
                    try {
                        foreach ($Disk in (Get-NcDiskOwner -Node $Owner -Controller $Array)) {
                            $inObj = [ordered] @{
                                'Disk' = $Disk.Name
                                'Owner Id' = $Disk.OwnerId
                                'Home' = $Disk.Home
                                'Home Id' = $Disk.HomeId
                                'Type' = $Disk.Type
                            }
                            $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                        }
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }
                $TableParams = @{
                    Name = "Node Disk Owner - $($Node)"
                    List = $false
                    ColumnWidths = 20, 20, 25, 20, 15
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