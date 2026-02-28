function Get-AbrOntapVserverDiagram {
    <#
    .SYNOPSIS
        Used by As Built Report to build NetApp ONTAP Vserver resources diagram
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
        $Vserver
    )

    begin {
        Write-PScriboMessage "Generating Vserver Diagram for $Vserver."
        # Used for DiagramDebug
        if ($Options.EnableDiagramDebug) {
            $EdgeDebug = @{style = 'filled'; color = 'red' }
            $SubGraphDebug = @{style = 'dashed'; color = 'red' }
            $NodeDebug = @{color = 'black'; style = 'red'; shape = 'plain' }
            $NodeDebugEdge = @{color = 'black'; style = 'red'; shape = 'plain' }
            $IconDebug = $true
        } else {
            $EdgeDebug = @{style = 'invis'; color = 'red' }
            $SubGraphDebug = @{style = 'invis'; color = 'gray' }
            $NodeDebug = @{color = 'transparent'; style = 'transparent'; shape = 'point' }
            $NodeDebugEdge = @{color = 'transparent'; style = 'transparent'; shape = 'none' }
            $IconDebug = $false
        }

        if ($Options.DiagramTheme -eq 'Black') {
            $Edgecolor = 'White'
            $Fontcolor = 'White'
        } elseif ($Options.DiagramTheme -eq 'Neon') {
            $Edgecolor = 'gold2'
            $Fontcolor = 'gold2'
        } else {
            $Edgecolor = '#71797E'
            $Fontcolor = '#565656'
        }
    }

    process {
        try {
            $ClusterInfo = Get-NcCluster -Controller $Array
            $VserverData = Get-NcVserver -VserverContext $Vserver | Where-Object { $_.VserverType -eq 'data' }
            $VserverAggrs = (Get-NcVol -VserverContext $Vserver -Controller $Array).Aggregate | ForEach-Object { Get-NcAggr -Name $_ } | Select-Object -Unique
            $VserverLifs = Get-NcNetInterface -Controller $Array | Where-Object { $_.Vserver -eq $Vserver -and $_.Role -eq 'data' }

            $VserverNodeName = Remove-SpecialChar -String $Vserver -SpecialChars '\-_'

            # SVM Additional Info
            $SVMAdditionalInfo = [PSCustomObject][ordered]@{
                'State' = switch ([string]::IsNullOrEmpty($VserverData.State)) {
                    $true { 'Unknown' }
                    $false { $TextInfo.ToTitleCase($VserverData.State) }
                    default { 'Unknown' }
                }
                'Protocols' = switch ([string]::IsNullOrEmpty($VserverData.AllowedProtocols)) {
                    $true { 'None' }
                    $false { ($VserverData.AllowedProtocols | Sort-Object) -join ', ' }
                    default { 'None' }
                }
                'IPSpace' = switch ([string]::IsNullOrEmpty($VserverData.Ipspace)) {
                    $true { 'Unknown' }
                    $false { $VserverData.Ipspace }
                    default { 'Unknown' }
                }
                'Root Vol' = switch ([string]::IsNullOrEmpty($VserverData.RootVolume)) {
                    $true { 'Unknown' }
                    $false { $VserverData.RootVolume }
                    default { 'Unknown' }
                }
            }

            # SVM node
            $SVMNodeObj = Add-DiaHtmlNodeTable -Name 'SVMNodeObj' -ImagesObj $Images -inputObject $Vserver -Align 'Center' -iconType 'Ontap_SVM' -ColumnSize 1 -IconDebug $IconDebug -MultiIcon -AditionalInfo $SVMAdditionalInfo -TableBorderColor '#71797E' -TableBorder '0' -FontSize 18

            if ($SVMNodeObj) {
                $SVMMgmtObj = Add-DiaHtmlSubGraph -Name 'SVMMgmtObj' -ImagesObj $Images -TableArray $SVMNodeObj -Align 'Right' -IconDebug $IconDebug -Label "Management: $($ClusterInfo.NcController)" -LabelPos 'down' -TableStyle 'dashed,rounded' -TableBorderColor '#71797E' -TableBorder 1 -ColumnSize 1 -FontSize 12

                if ($SVMMgmtObj) {
                    Node $VserverNodeName @{Label = $SVMMgmtObj; shape = 'plain'; fillColor = 'transparent'; fontsize = 14 }
                } else {
                    Write-PScriboMessage -IsWarning "Unable to create SVM Node for $Vserver."
                }
            }

            # Aggregates
            if ($VserverAggrs) {
                try {
                    $AggrInfo = @()
                    foreach ($Aggr in $VserverAggrs) {
                        $AggrData = Get-NcAggr -Name $Aggr.AggregateName -Controller $Array
                        $AggrInfo += [PSCustomObject][ordered]@{
                            'Name' = $Aggr.AggregateName
                            'AdditionalInfo' = [PSCustomObject][ordered]@{
                                'Raid Type' = switch ([string]::IsNullOrEmpty($Aggr.RaidType)) {
                                    $true { 'Unknown' }
                                    $false { $Aggr.RaidType }
                                    default { 'Unknown' }
                                }
                                'Available' = switch ([string]::IsNullOrEmpty($AggrData.Available)) {
                                    $true { 'Unknown' }
                                    $false { ($AggrData.Available | ConvertTo-FormattedNumber -NumberFormatString 0.0 -Type Datasize -ErrorAction SilentlyContinue) }
                                    default { 'Unknown' }
                                }
                                'SnapLock' = switch ([string]::IsNullOrEmpty($Aggr.SnaplockType)) {
                                    $true { 'None' }
                                    $false { $Aggr.SnaplockType }
                                    default { 'None' }
                                }
                            }
                        }
                    }

                    if ($AggrInfo.Count -eq 1) {
                        $AggrColumnSize = 1
                    } elseif ($ColumnSize) {
                        $AggrColumnSize = $ColumnSize
                    } else {
                        $AggrColumnSize = $AggrInfo.Count
                    }

                    $AggrNodeObj = Add-DiaHtmlNodeTable -Name 'AggrNodeObj' -ImagesObj $Images -inputObject $AggrInfo.Name -Align 'Center' -iconType 'Ontap_Aggregate' -ColumnSize $AggrColumnSize -IconDebug $IconDebug -MultiIcon -AditionalInfo $AggrInfo.AdditionalInfo -SubgraphTableStyle 'dashed,rounded' -TableBorderColor '#71797E' -TableBorder 1 -FontSize 18

                    if ($AggrNodeObj) {
                        $AggrSubGraphObj = Add-DiaHtmlSubGraph -Name 'AggrSubGraphObj' -ImagesObj $Images -TableArray $AggrNodeObj -Align 'Center' -IconDebug $IconDebug -Label 'Aggregates' -LabelPos 'top' -TableStyle 'dashed,rounded' -TableBorderColor $Edgecolor -TableBorder '1' -ColumnSize 1 -FontSize 18

                        if ($AggrSubGraphObj) {
                            Node "$($VserverNodeName)Aggrs" @{Label = $AggrSubGraphObj; shape = 'plain'; fillColor = 'transparent'; fontsize = 14 }
                            Edge -To "$($VserverNodeName)Aggrs" -From $VserverNodeName @{minlen = 2; color = $Edgecolor; style = 'filled'; arrowhead = 'box'; arrowtail = 'box' }
                        }
                    }
                } catch {
                    Write-PScriboMessage -IsWarning $_.Exception.Message
                }
            }

            # Volumes
            $VserverVolumes = Get-NcVol -VserverContext $Vserver -Controller $Array | Where-Object { $_.JunctionPath -ne '/' -and $_.Name -ne 'vol0' }
            if ($VserverVolumes) {
                try {
                    $VolInfo = @()
                    foreach ($Vol in $VserverVolumes) {
                        $VolInfo += [PSCustomObject][ordered]@{
                            'Name' = $Vol.Name
                            'AdditionalInfo' = [PSCustomObject][ordered]@{
                                'State' = switch ([string]::IsNullOrEmpty($Vol.State)) {
                                    $true { 'Unknown' }
                                    $false { $TextInfo.ToTitleCase($Vol.State) }
                                    default { 'Unknown' }
                                }
                                'Size' = switch ([string]::IsNullOrEmpty($Vol.Totalsize)) {
                                    $true { 'Unknown' }
                                    $false { ($Vol.Totalsize | ConvertTo-FormattedNumber -NumberFormatString 0.0 -Type DataSize -ErrorAction SilentlyContinue) }
                                    default { 'Unknown' }
                                }
                                'Used' = switch ([string]::IsNullOrEmpty($Vol.Used)) {
                                    $true { 'Unknown' }
                                    $false { ($Vol.Used | ConvertTo-FormattedNumber -ErrorAction SilentlyContinue -Type Percent) }
                                    default { 'Unknown' }
                                }
                                'Aggr' = switch ([string]::IsNullOrEmpty($Vol.Aggregate)) {
                                    $true { 'Unknown' }
                                    $false { $Vol.Aggregate }
                                    default { 'Unknown' }
                                }
                            }
                        }
                    }

                    if ($VolInfo.Count -eq 1) {
                        $VolColumnSize = 1
                    } elseif ($ColumnSize) {
                        $VolColumnSize = $ColumnSize
                    } else {
                        $VolColumnSize = $VolInfo.Count
                    }

                    $VolNodeObj = Add-DiaHtmlNodeTable -Name 'VolNodeObj' -ImagesObj $Images -inputObject $VolInfo.Name -Align 'Center' -iconType 'Ontap_Volume' -ColumnSize $VolColumnSize -IconDebug $IconDebug -MultiIcon -AditionalInfo $VolInfo.AdditionalInfo -SubgraphTableStyle 'dashed,rounded' -TableBorderColor '#71797E' -TableBorder 1 -FontSize 18

                    if ($VolNodeObj) {
                        $VolSubGraphObj = Add-DiaHtmlSubGraph -Name 'VolSubGraphObj' -ImagesObj $Images -TableArray $VolNodeObj -Align 'Center' -IconDebug $IconDebug -Label 'Volumes' -LabelPos 'top' -TableStyle 'dashed,rounded' -TableBorderColor $Edgecolor -TableBorder '1' -ColumnSize 1 -FontSize 18

                        if ($VolSubGraphObj) {
                            Node "$($VserverNodeName)Vols" @{Label = $VolSubGraphObj; shape = 'plain'; fillColor = 'transparent'; fontsize = 14 }
                            Edge -From $VserverNodeName -To "$($VserverNodeName)Vols" @{minlen = 2; color = $Edgecolor; style = 'filled'; arrowhead = 'box'; arrowtail = 'box' }
                        }
                    }
                } catch {
                    Write-PScriboMessage -IsWarning $_.Exception.Message
                }
            }

            # LIFs
            if ($VserverLifs) {
                try {
                    $LifInfo = @()
                    foreach ($Lif in $VserverLifs) {
                        $LifInfo += [PSCustomObject][ordered]@{
                            'Name' = $Lif.InterfaceName
                            'AdditionalInfo' = [PSCustomObject][ordered]@{
                                'IP' = switch ($Null -eq $Lif.Wwpn) {
                                    $true {
                                        switch ([string]::IsNullOrEmpty($Lif.Address)) {
                                            $true { 'Unknown' }
                                            $false { $Lif.Address }
                                            default { 'Unknown' }
                                        }
                                    }
                                    $false { $Lif.Wwpn }
                                }
                                'Protocol' = switch ([string]::IsNullOrEmpty($Lif.DataProtocols)) {
                                    $true { 'Unknown' }
                                    $false { ($Lif.DataProtocols | Sort-Object) -join ', ' }
                                    default { 'Unknown' }
                                }
                                'Status' = switch ($Lif.AdministrativeStatus) {
                                    'up' { 'Up' }
                                    'down' { 'Down' }
                                    default { 'Unknown' }
                                }
                                'Is Home?' = switch ($Lif.IsHome) {
                                    $true { 'Yes' }
                                    $false { 'No' }
                                    default { 'Unknown' }
                                }
                            }
                        }
                    }

                    if ($LifInfo.Count -eq 1) {
                        $LifColumnSize = 1
                    } elseif ($ColumnSize) {
                        $LifColumnSize = $ColumnSize
                    } else {
                        $LifColumnSize = $LifInfo.Countno_icon.png
                    }

                    $LifNodeObj = Add-DiaHtmlNodeTable -Name 'LifNodeObj' -ImagesObj $Images -inputObject $LifInfo.Name -Align 'Center' -iconType 'Ontap_Network_Nic' -ColumnSize $LifColumnSize -IconDebug $IconDebug -MultiIcon -AditionalInfo $LifInfo.AdditionalInfo -SubgraphTableStyle 'dashed,rounded' -TableBorderColor '#71797E' -TableBorder 1 -FontSize 18

                    if ($LifNodeObj) {
                        $LifSubGraphObj = Add-DiaHtmlSubGraph -Name 'LifSubGraphObj' -ImagesObj $Images -TableArray $LifNodeObj -Align 'Center' -IconDebug $IconDebug -Label 'Network Interfaces (LIFs)' -LabelPos 'top' -TableStyle 'dashed,rounded' -TableBorderColor $Edgecolor -TableBorder '1' -ColumnSize 1 -FontSize 18

                        if ($LifSubGraphObj) {
                            Node "$($VserverNodeName)Lifs" @{Label = $LifSubGraphObj; shape = 'plain'; fillColor = 'transparent'; fontsize = 14 }
                            Edge -From $VserverNodeName -To "$($VserverNodeName)Lifs" @{minlen = 2; color = $Edgecolor; style = 'filled'; arrowhead = 'box'; arrowtail = 'box' }
                        }
                    }
                } catch {
                    Write-PScriboMessage -IsWarning $_.Exception.Message
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning $_.Exception.Message
        }
    }

    end {}

}
