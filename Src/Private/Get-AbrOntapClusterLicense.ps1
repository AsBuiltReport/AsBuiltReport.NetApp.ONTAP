function Get-AbrOntapClusterLicense {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP cluster licenses information from the Cluster Management Network
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
        Write-PscriboMessage "Collecting ONTAP cluster license information."
    }

    process {
        $License = Get-NcLicense
        if ($License) {
            $LicenseSummary = foreach ($Licenses in $License) {
                $EntitlementRisk = Get-NcLicenseEntitlementRisk -Package $Licenses.Package
                [PSCustomObject] @{
                    'Name' = $Licenses.Owner
                    'Package' = $Licenses.Package
                    'Type' = $Licenses.Type
                    'Description' = $Licenses.Description
                    'Risk' = $EntitlementRisk.Risk
                }
            }
            if ($Healthcheck.License.RiskSummary) {
                $LicenseSummary | Where-Object { $_.'Risk' -like 'low' } | Set-Style -Style Ok -Property 'Risk'
                $LicenseSummary | Where-Object { $_.'Risk' -like 'medium' -or $_.'Risk' -like 'unknown' } | Set-Style -Style Warning -Property 'Risk'
                $LicenseSummary | Where-Object { $_.'Risk' -like 'High' } | Set-Style -Style Critical -Property 'Risk'
            }
            $TableParams = @{
                Name = "License Summary - $($ClusterInfo.ClusterName)"
                List = $false
                ColumnWidths = 30, 20, 10, 28, 12
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $LicenseSummary | Table @TableParams
        }
    }

    end {}

}