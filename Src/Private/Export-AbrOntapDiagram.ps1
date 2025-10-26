function Export-AbrOntapDiagram {
    <#
    .SYNOPSIS
    Used by As Built Report to export NetApp Ontap infrastructure diagram
    .DESCRIPTION
        Documents the configuration of NetApp Ontap in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.6.8
        Author:         Jonathan Colon
        Twitter:        @jcolonfzenpr
        Github:         rebelinux
        Credits:        Iain Brighton (@iainbrighton) - PScribo module

    .LINK
        https://github.com/AsBuiltReport/AsBuiltReport.NetApp.Ontap
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingCmdletAliases", "", Scope = "Function")]

    [CmdletBinding()]
    param (
        $DiagramObject,
        [string] $MainDiagramLabel = 'Change Me',
        [Parameter(Mandatory = $true)]
        [string] $FileName
    )

    begin {
        Write-PScriboMessage -Message "EnableDiagrams set to $($Options.EnableDiagrams)."
    }

    process {
        if ($Options.EnableDiagrams) {
            Write-PScriboMessage -Message "Collecting NetApp Ontap Infrastructure diagram"

            $RootPath = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
            [System.IO.FileInfo]$IconPath = Join-Path $RootPath 'icons'

            $DiagramParams = @{
                'FileName' = $FileName
                'OutputFolderPath' = $OutputFolderPath
                'MainDiagramLabel' = $MainDiagramLabel
                'MainDiagramLabelFontsize' = 28
                'MainDiagramLabelFontcolor' = '#565656'
                'MainDiagramLabelFontname' = 'Segoe UI Black'
                'IconPath' = $IconPath
                'ImagesObj' = $Images
                'LogoName' = 'AsBuiltReport_LOGO'
                'SignatureLogoName' = 'Abr_LOGO_Footer'
                'WaterMarkText' = $Options.DiagramWaterMark
                'Direction' = & {
                    if ($MainDiagramLabel -eq 'Cluster Replication Diagram') {
                        'left-to-right'
                    } else {
                        'top-to-bottom'
                    }
                }
            }

            if ($Options.DiagramTheme -eq 'Black') {
                $DiagramParams.add('MainGraphBGColor', 'Black')
                $DiagramParams.add('Edgecolor', 'White')
                $DiagramParams.add('Fontcolor', 'White')
                $DiagramParams.add('NodeFontcolor', 'White')
                $DiagramParams.add('WaterMarkColor', 'White')
            } elseif ($Options.DiagramTheme -eq 'Neon') {
                $DiagramParams.add('MainGraphBGColor', 'grey14')
                $DiagramParams.add('Edgecolor', 'gold2')
                $DiagramParams.add('Fontcolor', 'gold2')
                $DiagramParams.add('NodeFontcolor', 'gold2')
                $DiagramParams.add('WaterMarkColor', '#FFD700')
            } else {
                $DiagramParams.add('WaterMarkColor', '#333333')
            }

            if ($Options.ExportDiagrams) {
                if (-not $Options.ExportDiagramsFormat) {
                    $DiagramFormat = 'png'
                } else {
                    $DiagramFormat = $Options.ExportDiagramsFormat
                }
                $DiagramParams.Add('Format', $DiagramFormat)
            } else {
                $DiagramParams.Add('Format', "base64")
            }

            if ($Options.EnableDiagramDebug) {

                $DiagramParams.Add('DraftMode', $True)

            }

            if ($Options.EnableDiagramSignature) {
                $DiagramParams.Add('Signature', $True)
                $DiagramParams.Add('AuthorName', $Options.SignatureAuthorName)
                $DiagramParams.Add('CompanyName', $Options.SignatureCompanyName)
            }

            if ($Options.ExportDiagrams) {
                try {
                    Write-PScriboMessage -Message "Generating NetApp Ontap diagram"
                    $Graph = $DiagramObject
                    if ($Graph) {
                        Write-PScriboMessage -Message "Saving NetApp Ontap diagram"
                        $Diagram = New-Diagrammer @DiagramParams -InputObject $Graph
                        if ($Diagram) {
                            foreach ($OutputFormat in $DiagramFormat) {
                                Write-Information -MessageData "Saved '$($FileName).$($OutputFormat)' diagram to '$($OutputFolderPath)'." -InformationAction Continue
                            }
                        }
                    }
                } catch {
                    Write-PScriboMessage -IsWarning -Message "Unable to export the NetApp Diagram: $($_.Exception.Message)"
                }
            }
            try {
                $DiagramParams.Remove('Format')
                $DiagramParams.Add('Format', "base64")

                $Graph = $DiagramObject
                $Diagram = New-Diagrammer @DiagramParams -InputObject $Graph
                if ($Diagram) {
                    if ((Get-DiaImagePercent -GraphObj $Diagram).Width -gt 600) { $ImagePrty = 40 } else { $ImagePrty = 30 }
                    Section -Style Heading2 $MainDiagramLabel {
                        Image -Base64 $Diagram -Text "NetApp Ontap Diagram" -Percent $ImagePrty -Align Center
                        Paragraph "Image preview: Opens the image in a new tab to view it at full resolution." -Tabs 2
                    }
                }
            } catch {
                Write-PScriboMessage -IsWarning -Message "Unable to generate the Ontap Diagram: $($_.Exception.Message)"
            }
        }
    }

    end {}
}