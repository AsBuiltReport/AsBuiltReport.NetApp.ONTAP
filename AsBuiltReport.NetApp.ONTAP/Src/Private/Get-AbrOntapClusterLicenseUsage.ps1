function Get-AbrOntapClusterLicenseUsage {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP cluster licenses usage information from the Cluster Management Network
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
        Write-PScriboMessage 'Collecting ONTAP cluster license usage information.'
    }

    process {
        try {
            $LicenseFeature = Get-NcFeatureStatus -Controller $Array
            if ($LicenseFeature) {
                $OutObj = @()
                foreach ($NodeLFs in $LicenseFeature) {
                    $inObj = [ordered] @{
                        'Name' = $NodeLFs.FeatureName
                        'Status' = $NodeLFs.Status
                        'Notes' = $NodeLFs.Notes
                    }
                    $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                }
                $TableParams = @{
                    Name = "License Feature - $($ClusterInfo.ClusterName)"
                    List = $false
                    ColumnWidths = 40, 20, 40
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