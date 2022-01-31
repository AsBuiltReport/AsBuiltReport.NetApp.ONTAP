function Get-AbrOntapVserverVolumesQuota {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP vserver volumes quota information from the Cluster Management Network
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
        Write-PscriboMessage "Collecting ONTAP Vserver volumes quota information."
    }

    process {
        try {
            Section -Style Heading6 "$Vserver Vserver Volume Quota Status" {
                Paragraph "The following section provides the $Vserver Volumes Quota Status Information on $($ClusterInfo.ClusterName)."
                BlankLine
                $VserverQuotaStatus = Get-NcQuotaStatus -VserverContext $Vserver -Controller $Array
                $VserverObj = @()
                if ($VserverQuotaStatus) {
                    foreach ($Item in $VserverQuotaStatus) {
                        try {
                            $inObj = [ordered] @{
                                'Volume' = $Item.Volume
                                'Status' = $Item.Status
                                'Substatus' = $Item.Substatus
                            }
                            $VserverObj += [pscustomobject]$inobj
                            if ($null -ne $Item.QuotaErrorMsgs) {
                                $VserverObj.Add('Quota Error', $Item.QuotaErrorMsgs)
                            }
                        }
                        catch {
                            Write-PscriboMessage -IsWarning $_.Exception.Message
                        }
                    }
                    if ($Healthcheck.Vserver.Quota) {
                        $VserverObj | Where-Object { $null -ne $_.'Quota Error' } | Set-Style -Style Warning -Property 'Quota Error'
                    }

                    $TableParams = @{
                        Name = "Vserver Volume Quota Status - $($Vserver)"
                        List = $false
                        ColumnWidths = 50, 25, 25
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $VserverObj | Table @TableParams
                }
            }
        }
        catch {
            Write-PscriboMessage -IsWarning $_.Exception.Message
        }
        try {
            if ($InfoLevel.Vserver -ge 2) {
                try {
                    Section -Style Heading6 "$Vserver Vserver Volume Quota Information" {
                        Paragraph "The following section provides the $Vserver Volumes Quota Information on $($ClusterInfo.ClusterName)."
                        BlankLine
                        $VserverQuota = Get-NcQuota -VserverContext $Vserver -Controller $Array
                        $VserverObj = @()
                        if ($VserverQuota) {
                            foreach ($Item in $VserverQuota) {
                                try {
                                    $inObj = [ordered] @{
                                        'Volume' = $Item.Volume
                                        'Type' = $Item.QuotaType
                                        'Target' = $Item.QuotaTarget
                                        'Disk Limit' = Switch ($Item.DiskLimit) {
                                            "-" { $Item.DiskLimit }
                                            default { $Item.DiskLimit | ConvertTo-FormattedNumber -Type DataSize -ErrorAction SilentlyContinue }
                                        }
                                        'File Limit' = Switch ($Item.FileLimit) {
                                            "-" { $Item.FileLimit }
                                            default { $Item.FileLimit | ConvertTo-FormattedNumber -Type Count -ErrorAction SilentlyContinue }
                                        }
                                        'Soft Disk Limit' = Switch ($Item.SoftDiskLimit) {
                                            "-" { $Item.SoftDiskLimit }
                                            default { $Item.SoftDiskLimit | ConvertTo-FormattedNumber -Type DataSize -ErrorAction SilentlyContinue }
                                        }
                                        'Soft File Limit' = Switch ($Item.SoftFileLimit) {
                                            "-" { $Item.SoftFileLimit }
                                            default { $Item.SoftFileLimit | ConvertTo-FormattedNumber -Type Count -ErrorAction SilentlyContinue }
                                        }
                                    }
                                    $VserverObj += [pscustomobject]$inobj
                                    if ($null -ne $Item.QuotaError) {
                                        $VserverObj.Add('Quota Error', $Item.QuotaError)
                                    }
                                }
                                catch {
                                    Write-PscriboMessage -IsWarning $_.Exception.Message
                                }
                            }

                            if ($Healthcheck.Vserver.Quota) {
                                $VserverObj | Where-Object { $null -ne $_.'Quota Error' } | Set-Style -Style Warning -Property 'Quota Error'
                            }

                            $TableParams = @{
                                Name = "Vserver Volume Quota - $($Vserver)"
                                List = $false
                                ColumnWidths = 15, 13, 20, 13, 13, 13, 13
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $VserverObj | Table @TableParams
                        }
                    }
                }
                catch {
                    Write-PscriboMessage -IsWarning $_.Exception.Message
                }
                try {
                    Section -Style Heading6 "$Vserver Vserver Volume Quota Report (Disk)" {
                        Paragraph "The following section provides the $Vserver Volumes Quota Report (Disk) Information on $($ClusterInfo.ClusterName)."
                        BlankLine
                        $VserverQuotaReport = Get-NcQuotaReport -VserverContext $Vserver -Controller $Array
                        $VserverObj = @()
                        if ($VserverQuotaReport) {
                            foreach ($Item in $VserverQuotaReport) {
                                try {
                                    $inObj = [ordered] @{
                                        'Volume' = $Item.Volume
                                        'Quota Target' = $Item.QuotaTarget
                                        'Qtree' = $Item.Qtree
                                        'Disk Limit' = Switch ($Item.DiskLimit) {
                                            "-" { $Item.DiskLimit }
                                            default { $Item.DiskLimit | ConvertTo-FormattedNumber -Type DataSize -ErrorAction SilentlyContinue }
                                        }
                                        'Soft Disk Limit' = Switch ($Item.SoftDiskLimit) {
                                            "-" { $Item.SoftDiskLimit }
                                            default { $Item.SoftDiskLimit | ConvertTo-FormattedNumber -Type DataSize -ErrorAction SilentlyContinue }
                                        }
                                        'Disk Used' = $Item.DiskUsed | ConvertTo-FormattedNumber -Type DataSize -ErrorAction SilentlyContinue
                                    }
                                    $VserverObj += [pscustomobject]$inobj
                                }
                                catch {
                                    Write-PscriboMessage -IsWarning $_.Exception.Message
                                }
                            }
                            if ($null -ne $Item.QuotaError) {
                                $VserverObj.Add('Quota Error', $Item.QuotaError)
                            }
                            if ($Healthcheck.Vserver.Quota) {
                                $VserverObj | Where-Object { $null -ne $_.'Quota Error' } | Set-Style -Style Warning -Property 'Quota Error'
                            }

                            $TableParams = @{
                                Name = "Vserver Volume Quota Report (Disk) - $($Vserver)"
                                List = $false
                                ColumnWidths = 20, 20, 15, 15, 15, 15
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $VserverObj | Table @TableParams
                        }
                    }
                }
                catch {
                    Write-PscriboMessage -IsWarning $_.Exception.Message
                }
                try {
                    Section -Style Heading6 "$Vserver Vserver Volume Quota Report (File)" {
                        Paragraph "The following section provides the $Vserver Volumes Quota Report (File) Information on $($ClusterInfo.ClusterName)."
                        BlankLine
                        $VserverQuotaReport = Get-NcQuotaReport -VserverContext $Vserver -Controller $Array
                        $VserverObj = @()
                        if ($VserverQuotaReport) {
                            foreach ($Item in $VserverQuotaReport) {
                                try {
                                    $inObj = [ordered] @{
                                        'Volume' = $Item.Volume
                                        'Quota Target' = $Item.QuotaTarget
                                        'Qtree' = $Item.Qtree
                                        'File Limit' = Switch ($Item.FileLimit) {
                                            "-" { $Item.FileLimit }
                                            default { $Item.FileLimit | ConvertTo-FormattedNumber -Type Count -ErrorAction SilentlyContinue }
                                        }
                                        'Soft File Limit' = Switch ($Item.SoftFileLimit) {
                                            "-" { $Item.SoftFileLimit }
                                            default { $Item.SoftFileLimit | ConvertTo-FormattedNumber -Type Count -ErrorAction SilentlyContinue }
                                        }
                                        'Files Used' = $Item.FilesUsed | ConvertTo-FormattedNumber -Type Count -ErrorAction SilentlyContinue
                                    }
                                    $VserverObj += [pscustomobject]$inobj
                                }
                                catch {
                                    Write-PscriboMessage -IsWarning $_.Exception.Message
                                }
                            }

                            $TableParams = @{
                                Name = "Vserver Volume Quota Report (File) - $($Vserver)"
                                List = $false
                                ColumnWidths = 20, 20, 15, 15, 15, 15
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $VserverObj | Table @TableParams
                        }
                    }
                }
                catch {
                    Write-PscriboMessage -IsWarning $_.Exception.Message
                }
            }
        }
        catch {
            Write-PscriboMessage -IsWarning $_.Exception.Message
        }
    }

    end {}

}