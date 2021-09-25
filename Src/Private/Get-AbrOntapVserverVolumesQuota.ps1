
function Get-AbrOntapVserverVolumesQuota {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP vserver volumes quota information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.4.0
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
        Write-PscriboMessage "Collecting ONTAP Vserver volumes quota information."
    }

    process {
        Section -Style Heading6 'Vserver Volume Quota Status' {
            Paragraph "The following section provides the Volumes Quota Status Information on $($ClusterInfo.ClusterName)."
            BlankLine
            $VserverQuotaStatus = Get-NcQuotaStatus
            $VserverObj = @()
            if ($VserverQuotaStatus) {
                foreach ($Item in $VserverQuotaStatus) {
                    $inObj = [ordered] @{
                        'Volume' = $Item.Volume
                        'Status' = $Item.Status
                        'Substatus' = $Item.Substatus
                        'Vserver' = $Item.Vserver
                    }
                    $VserverObj += [pscustomobject]$inobj
                    if ($null -ne $Item.QuotaErrorMsgs) {
                        $VserverObj.Add('Quota Error', $Item.QuotaErrorMsgs)
                    }

                }
                if ($Healthcheck.Vserver.Quota) {
                    $VserverObj | Where-Object { $null -ne $_.'Quota Error' } | Set-Style -Style Warning -Property 'Quota Error'
                }

                $TableParams = @{
                    Name = "Vserver Volume Quota Status Information - $($ClusterInfo.ClusterName)"
                    List = $false
                    ColumnWidths = 45, 15, 15, 25
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $VserverObj | Table @TableParams
            }
        }
        Section -Style Heading6 'Vserver Volume Quota Information' {
            Paragraph "The following section provides the Volumes Quota Information on $($ClusterInfo.ClusterName)."
            BlankLine
            $VserverQuota = Get-NcQuota
            $VserverObj = @()
            if ($VserverQuota) {
                foreach ($Item in $VserverQuota) {
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
                        'Vserver' = $Item.Vserver
                    }
                    $VserverObj += [pscustomobject]$inobj
                    if ($null -ne $Item.QuotaError) {
                        $VserverObj.Add('Quota Error', $Item.QuotaError)
                    }
                }

                if ($Healthcheck.Vserver.Quota) {
                    $VserverObj | Where-Object { $null -ne $_.'Quota Error' } | Set-Style -Style Warning -Property 'Quota Error'
                }

                $TableParams = @{
                    Name = "Vserver Volume Quota Information - $($ClusterInfo.ClusterName)"
                    List = $false
                    ColumnWidths = 15, 10, 20, 10, 10, 10, 10, 15
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $VserverObj | Table @TableParams
            }
        }
        Section -Style Heading6 'Vserver Volume Quota Report (Disk) Summary' {
            Paragraph "The following section provides the Volumes Quota Report (Disk) Information on $($ClusterInfo.ClusterName)."
            BlankLine
            $VserverQuotaReport = Get-NcQuotaReport
            $VserverObj = @()
            if ($VserverQuotaReport) {
                foreach ($Item in $VserverQuotaReport) {
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
                        'Vserver' = $Item.Vserver
                    }
                    $VserverObj += [pscustomobject]$inobj
                }
                if ($null -ne $Item.QuotaError) {
                    $VserverObj.Add('Quota Error', $Item.QuotaError)
                }
                if ($Healthcheck.Vserver.Quota) {
                    $VserverObj | Where-Object { $null -ne $_.'Quota Error' } | Set-Style -Style Warning -Property 'Quota Error'
                }

                $TableParams = @{
                    Name = "Vserver Volume Quota Report (Disk) Information - $($ClusterInfo.ClusterName)"
                    List = $false
                    ColumnWidths = 15, 19, 15, 12, 12, 12, 15
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $VserverObj | Table @TableParams
            }
        }
        Section -Style Heading6 'Vserver Volume Quota Report (File) Summary' {
            Paragraph "The following section provides the Volumes Quota Report (File) Information on $($ClusterInfo.ClusterName)."
            BlankLine
            $VserverQuotaReport = Get-NcQuotaReport
            $VserverObj = @()
            if ($VserverQuotaReport) {
                foreach ($Item in $VserverQuotaReport) {
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
                        'Vserver' = $Item.Vserver
                    }
                    $VserverObj += [pscustomobject]$inobj
                }

                $TableParams = @{
                    Name = "Vserver Volume Quota Report (File) Information - $($ClusterInfo.ClusterName)"
                    List = $false
                    ColumnWidths = 15, 19, 15, 12, 12, 12, 15
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $VserverObj | Table @TableParams
            }
        }
    }

    end {}

}