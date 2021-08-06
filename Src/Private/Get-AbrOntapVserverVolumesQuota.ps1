
function Set-Metric ($value, $limit){
    if ($value -gt 0) {
        if ($value -lt 3 -and $limit -ne '-' ) {
            $value = "$($limit)KB"
            return $value
        }
        elseif ($value -in 4..6) {
            $value = "$($limit / 1KB)MB"
            return $value
        }
        elseif ($value -in 7..9) {
            $value = "$($limit / 1MB)GB"
            return $value
        }
        elseif ($value -in 10..11) {
            $value = "$($limit / 1GB)TB"
            return $value
        }
        elseif ($value -in 12..14) {
            $value = "$($limit / 1TB)PB"
            return $value
        }
        else {
            $value = $limit
            return $value
        }
    }
}
function Get-AbrOntapVserverVolumesQuota {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP vserver volumes quota information from the Cluster Management Network
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
        Write-PscriboMessage "Collecting ONTAP Vserver volumes quota information."
    }

    process {
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
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $VserverObj | Table @TableParams
        }
        $VserverQuota = Get-NcQuota
        $VserverObj = @()
        if ($VserverQuota) {
            foreach ($Item in $VserverQuota) {
                $Item.DiskLimit = Set-Metric $Item.DiskLimit.Length $Item.DiskLimit
                $Item.SoftDiskLimit = Set-Metric $Item.SoftDiskLimit.Length $Item.SoftDiskLimit
                $inObj = [ordered] @{
                    'Volume' = $Item.Volume
                    'Type' = $Item.QuotaType
                    'Target' = $Item.QuotaTarget
                    'Disk Limit' = $Item.DiskLimit
                    'File Limit' = $Item.FileLimit
                    'Soft Disk Limit' = $Item.SoftDiskLimit
                    'Soft File Limit' = $Item.SoftFileLimit
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
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $VserverObj | Table @TableParams
        }
        $VserverQuotaReport = Get-NcQuotaReport
        $VserverObj = @()
        if ($VserverQuotaReport) {
            foreach ($Item in $VserverQuotaReport) {
                $Item.DiskLimit = Set-Metric $Item.DiskLimit.Length $Item.DiskLimit
                $Item.SoftDiskLimit = Set-Metric $Item.SoftDiskLimit.Length $Item.SoftDiskLimit
                $Item.DiskUsed = Set-Metric $Item.DiskUsed.Length $Item.DiskUsed
                $inObj = [ordered] @{
                    'Volume' = $Item.Volume
                    'Quota Target' = $Item.QuotaTarget
                    'Qtree' = $Item.Qtree
                    'Disk Limit' = $Item.DiskLimit
                    'Soft Disk Limit' = $Item.SoftDiskLimit
                    'Disk Used' = $Item.DiskUsed
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
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $VserverObj | Table @TableParams
        }
        $VserverQuotaReport = Get-NcQuotaReport
        $VserverObj = @()
        if ($VserverQuotaReport) {
            foreach ($Item in $VserverQuotaReport) {
                $inObj = [ordered] @{
                    'Volume' = $Item.Volume
                    'Quota Target' = $Item.QuotaTarget
                    'Qtree' = $Item.Qtree
                    'Files Limit' = $Item.FileLimit
                    'Soft File Limit' = $Item.SoftFileLimit
                    'Files Used' = $Item.FilesUsed
                    'Vserver' = $Item.Vserver
                }
                $VserverObj += [pscustomobject]$inobj
            }

            $TableParams = @{
                Name = "Vserver Volume Quota Report (File) Information - $($ClusterInfo.ClusterName)"
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