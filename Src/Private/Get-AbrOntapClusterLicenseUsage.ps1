function Get-AbrOntapClusterLicenseUsage {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP cluster licenses usage information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.6.7
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
        Write-PScriboMessage "Collecting ONTAP cluster license usage information."
    }

    process {
        try {
            $LicenseFeature = Get-NcFeatureStatus -Controller $Array
            if ($LicenseFeature) {
                $LicenseFeature = foreach ($NodeLFs in $LicenseFeature) {
                    [PSCustomObject] @{
                        'Name' = $NodeLFs.FeatureName
                        'Status' = $NodeLFs.Status
                        'Notes' = Switch ($NodeLFs.Notes) {
                            "-" { 'None' }
                            default { $NodeLFs.Notes }
                        }
                    }
                }
                $TableParams = @{
                    Name = "License Feature - $($ClusterInfo.ClusterName)"
                    List = $false
                    ColumnWidths = 40, 20, 40
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $LicenseFeature | Table @TableParams
            }
        } catch {
            Write-PScriboMessage -IsWarning $_.Exception.Message
        }
    }

    end {}

}