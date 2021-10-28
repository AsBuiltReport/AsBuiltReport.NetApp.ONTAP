function Get-AbrOntapClusterLicense {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP cluster licenses information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.5.0
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
        $Nodes = Get-NcNode -Controller $Array
        foreach ($Node in $Nodes) {
            Section -Style Heading3 "$Node License Usage" {
                Paragraph "The following section provides per node installed licenses on $($ClusterInfo.ClusterName)."
                BlankLine
                $License = Get-NcLicense -Owner $Node -Controller $Array
                if ($License) {
                    $LicenseSummary = foreach ($Licenses in $License) {
                        $EntitlementRisk = Get-NcLicenseEntitlementRisk -Package $Licenses.Package -Controller $Array
                        [PSCustomObject] @{
                            'License' = $TextInfo.ToTitleCase($Licenses.Package)
                            'Type' = $TextInfo.ToTitleCase($Licenses.Type)
                            'Description' = $Licenses.Description
                            'Risk' = ConvertTo-EmptyToFiller $EntitlementRisk.Risk
                        }
                    }
                    if ($Healthcheck.License.RiskSummary) {
                        $LicenseSummary | Where-Object { $_.'Risk' -like 'medium' -or $_.'Risk' -like 'unknown' -or $_.'Risk' -like 'unlicensed' } | Set-Style -Style Warning -Property 'Risk'
                        $LicenseSummary | Where-Object { $_.'Risk' -like 'High' } | Set-Style -Style Critical -Property 'Risk'
                    }
                    $TableParams = @{
                        Name = "License Usage - $($Node)"
                        List = $false
                        ColumnWidths = 25, 15, 38, 22
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $LicenseSummary | Table @TableParams
                }
            }
        }
    }

    end {}

}