function Get-AbrOntapVserverVolumesLanguage {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP vserver per volumes language attributes information from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.6.12
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
        Write-PScriboMessage 'Collecting ONTAP Vserver per volumes language attributes information.'
    }

    process {
        try {
            $VolumeFilter = Get-NcVol -VserverContext $Vserver -Controller $Array | Where-Object { $_.JunctionPath -ne '/' -and $_.Name -ne 'vol0' }
            $OutObj = @()
            if ($VolumeFilter) {
                foreach ($Item in $VolumeFilter) {
                    try {
                        $LangAttr = $Item.VolumeLanguageAttributes
                        $inObj = [ordered] @{
                            'Volume' = $Item.Name
                            'Language' = $LangAttr.Language ?? '--'
                            'Language Code' = $LangAttr.LanguageCode ?? '--'
                            'Convert Ucode Enabled' = $LangAttr.IsConvertUcodeEnabled
                            'Create Ucode Enabled' = $LangAttr.IsCreateUcodeEnabled
                        }
                        $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                }

                $TableParams = @{
                    Name = "Per Volume Language Attributes - $($Vserver)"
                    List = $false
                    ColumnWidths = 22, 30, 20, 14, 14
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
