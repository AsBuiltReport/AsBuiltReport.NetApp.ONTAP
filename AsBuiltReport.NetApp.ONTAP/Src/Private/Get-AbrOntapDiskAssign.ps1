function Get-AbrOntapDiskAssign {
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
    )

    begin {
        Write-PScriboMessage 'Collecting ONTAP disk assignment per node information.'
    }

    process {
        try {
            $NodeDiskCount = Get-NcDisk -Controller $Array | ForEach-Object { $_.DiskOwnershipInfo.HomeNodeName } | Group-Object
            if ($NodeDiskCount) {
                $ChartData = @()
                $OwnerName = @()
                $OutObj = @()
                foreach ($Disks in $NodeDiskCount) {
                    $OwnerName += $Disks.Name
                    $ChartData += $Disks.Count
                    $inObj = [ordered] @{
                        'Node' = $Disks.Name
                        'Disk Count' = $Disks | Select-Object -ExpandProperty Count
                    }
                    $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                }
                $TableParams = @{
                    Name = "Assigned Disk - $($ClusterInfo.ClusterName)"
                    List = $false
                    ColumnWidths = 50, 50
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $OutObj | Table @TableParams
            }
            try {
                $Chart = New-BarChart -Values $ChartData -Labels $OwnerName -Title 'Disk Assignment' -EnableLegend -LegendOrientation Horizontal -LegendAlignment UpperCenter -Width 600 -Height 600 -Format base64 -LabelYAxis 'Disk Count' -LabelXAxis 'Nodes' -TitleFontSize 20 -TitleFontBold -AreaOrientation Vertical -EnableCustomColorPalette -CustomColorPalette @('#395879', '#59779a', '#7b98bc', '#9dbae0', '#c0ddff') -AxesMarginsTop 0.5
                if ($Chart) {
                    Section -Style NOTOCHeading5 -ExcludeFromTOC 'Per Node Disk Assignment - Chart' {
                        Image -Text 'Per Node Disk Assignment - Chart' -Align 'Center' -Percent 100 -Base64 $Chart
                    }
                }
            } catch {
                Write-PScriboMessage -IsWarning $_.Exception.Message
            }
        } catch {
            Write-PScriboMessage -IsWarning $_.Exception.Message
        }
    }

    end {}

}