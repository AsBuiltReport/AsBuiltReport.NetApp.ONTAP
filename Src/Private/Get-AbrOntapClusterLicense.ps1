function Get-AbrOntapClusterLicense {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP cluster licenses information from the Cluster Management Network
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
        Write-PScriboMessage 'Collecting ONTAP cluster license information.'
    }

    process {
        try {
            $Nodes = Get-NcNode -Controller $Array
            foreach ($Node in $Nodes) {
                try {
                    $License = Get-NcLicense -Owner $Node -Controller $Array
                    if ($License) {
                        Section -Style Heading3 "$Node License Usage" {
                            $OutObj = @()
                            foreach ($Licenses in $License) {
                                $EntitlementRisk = try { Get-NcLicenseEntitlementRisk -Package $Licenses.Package -Controller $Array -ErrorAction SilentlyContinue } catch { Write-PScriboMessage -IsWarning $_.Exception.Message }
                                $inObj = [ordered] @{
                                    'License' = $TextInfo.ToTitleCase($Licenses.Package)
                                    'Type' = $TextInfo.ToTitleCase($Licenses.Type)
                                    'Description' = $Licenses.Description
                                    'Risk' = (Get-NcLicenseEntitlementRisk -Package $Licenses.Package -Controller $Array).Risk ?? '--'
                                }
                                $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                            }
                            if ($Healthcheck.License.RiskSummary) {
                                $OutObj | Where-Object { $_.'Risk' -like 'medium' -or $_.'Risk' -like 'unknown' -or $_.'Risk' -like 'unlicensed' } | Set-Style -Style Warning -Property 'Risk'
                                $OutObj | Where-Object { $_.'Risk' -like 'High' } | Set-Style -Style Critical -Property 'Risk'
                            }
                            $TableParams = @{
                                Name = "License Usage - $($Node)"
                                List = $false
                                ColumnWidths = 25, 15, 38, 22
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $OutObj | Table @TableParams
                            if ($Healthcheck.License.RiskSummary -and ($OutObj | Where-Object { $_.'Risk' -like 'medium' -or $_.'Risk' -like 'unknown' -or $_.'Risk' -like 'unlicensed' }) -or ($OutObj | Where-Object { $_.'Risk' -like 'High' })) {
                                Paragraph 'Health Check:' -Bold -Underline
                                BlankLine
                                Paragraph {
                                    Text 'Best Practice:' -Bold
                                    Text 'Review the license risk summary above. It is recommended to address any licenses with medium, high, unknown, or unlicensed risk to ensure compliance and avoid potential disruptions.'
                                }
                                BlankLine
                            }
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