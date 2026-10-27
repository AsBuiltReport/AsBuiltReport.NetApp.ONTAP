# Copilot Instructions for AsBuiltReport.NetApp.ONTAP

## Project Overview

PowerShell 7 module that generates as-built documentation (HTML, Word, Text) for NetApp ONTAP storage clusters. It is part of the broader **AsBuiltReport** framework and uses **PScribo** for document rendering.

**Requires PowerShell 7+ (Core only — not compatible with Windows PowerShell 5.1).**

## Linting

Run PSScriptAnalyzer locally (mirrors the CI check):

```powershell
Invoke-ScriptAnalyzer -Path ./AsBuiltReport.NetApp.ONTAP/Src `
    -Recurse `
    -Settings ./.github/workflows/PSScriptAnalyzerSettings.psd1
```

Excluded rules (defined in `.github/workflows/PSScriptAnalyzerSettings.psd1`):
- `PSUseToExportFieldsInManifest`
- `PSReviewUnusedParameter`
- `PSUseDeclaredVarsMoreThanAssignments`
- `PSAvoidGlobalVars`

CI linting is in `.github/workflows/PSScriptAnalyzer.yml` (runs on every push/PR).

## Running the Report (Manual Testing)

There are no automated Pester tests. Testing is done by generating a real report against an ONTAP cluster:

```powershell
$Cred = Get-Credential
New-AsBuiltReport -Report NetApp.ONTAP `
    -Target <cluster-mgmt-ip> `
    -Credential $Cred `
    -Format HTML `
    -OutputFolderPath "$env:HOME/reports"
```

With health checks and all formats:

```powershell
New-AsBuiltReport -Report NetApp.ONTAP `
    -Target <cluster-mgmt-ip> `
    -Credential $Cred `
    -Format HTML,Word `
    -EnableHealthCheck `
    -OutputFolderPath "$env:HOME/reports"
```

## Architecture

### Module Layout

```
AsBuiltReport.NetApp.ONTAP/
├── AsBuiltReport.NetApp.ONTAP.psd1       # Module manifest (required deps, version)
├── AsBuiltReport.NetApp.ONTAP.psm1       # Root module — auto-loads all Src/ files
├── AsBuiltReport.NetApp.ONTAP.json       # Report configuration template (user-facing)
├── AsBuiltReport.NetApp.ONTAP.Style.ps1  # PScribo document styles
├── icons/                                # PNG icons embedded in diagrams
└── Src/
    ├── Public/
    │   └── Invoke-AsBuiltReport.NetApp.ONTAP.ps1  # Single exported entry point (985 lines)
    └── Private/
        ├── Get-AbrOntap*.ps1             # 100+ data collection & rendering functions
        ├── ConvertTo-TextYN.ps1          # Boolean → Yes/No helper
        ├── ConvertTo-HashToYN.ps1        # Hashtable value → Yes/No helper
        ├── Export-AbrOntapDiagram.ps1    # Diagram export helper
        └── Get-NetAppOntapAPI.ps1        # REST API wrapper
```

### Data Flow

1. **Entry point** (`Invoke-AsBuiltReport.NetApp.ONTAP.ps1`) validates PS version, connects to ONTAP via `Connect-NcController`, reads the JSON config, then calls each `Get-AbrOntap*` function in section order.
2. **Data collection** — each `Get-AbrOntap*` calls NetApp.ONTAP cmdlets (`Get-NcCluster`, `Get-NcAggr`, etc.) and populates `[ordered]` hashtables.
3. **Rendering** — collected data is passed to PScribo (`Table`, `Paragraph`, `Section`, `Heading*`). Tables use `Set-Style` for health-check color coding.
4. **Diagrams** — `Get-AbrOntapClusterDiagram` and similar functions use `AsBuiltReport.Diagram` to produce topology graphs; `Export-AbrOntapDiagram` writes them to disk.
5. **Output** — PScribo serializes to HTML/Word/Text via `New-Document`.

### Script-Scoped Variables (set by the framework, available in all Private functions)

| Variable | Content |
|---|---|
| `$Array` | Active `NcController` connection object |
| `$script:Report` | Report config from JSON (`ShowTableCaptions`, etc.) |
| `$script:InfoLevel` | Per-section detail level (0 = disabled, 1 = summary, 2 = advanced) |
| `$script:Options` | User options (diagram theme, excluded Vservers, etc.) |
| `$script:Healthcheck` | Health check enable/disable flags per component |
| `$script:TextInfo` | `CultureInfo` for text casing |
| `$script:Images` | Hashtable of icon paths for diagrams |

### InfoLevel Behavior

Every section is gated on `$InfoLevel.<Section>`:
- `0` — Skip entirely
- `1` — Summary view (key fields only)
- `2` — Advanced view (adds metrics, extended attributes, charts)

## Key Conventions

### Function Template

Every `Get-AbrOntap*` private function follows this structure:

```powershell
function Get-AbrOntap{Component}{Feature} {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp ONTAP {description}
    .NOTES
        Version:  0.6.x
        Author:   Jonathan Colon
    #>
    [CmdletBinding()]
    param ()

    begin {
        Write-PScriboMessage 'Collecting ONTAP {feature} information.'
    }

    process {
        try {
            $Data = Get-Nc{Feature} -Controller $Array
            if ($Data) {
                $OutObj = @()
                $inObj = [ordered] @{
                    'Friendly Label' = $Data.Property ?? '--'
                }
                $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)

                # Health check styling
                if ($Healthcheck.{Component}.{Feature}) {
                    $OutObj | Where-Object { $_.'Status' -ne 'OK' } | Set-Style -Style Critical -Property 'Status'
                }

                $TableParams = @{
                    Name = "Table Title - $($Array.Name)"
                    List = $true
                    ColumnWidths = 25, 75
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
}
```

### Naming

- **Private functions**: `Get-AbrOntap{Category}{Feature}` (e.g., `Get-AbrOntapStorageAGGR`, `Get-AbrOntapVserverVolumes`)
- **One function per file** — filename matches function name exactly
- **Local variables**: PascalCase (`$ClusterInfo`, `$OutObj`, `$inObj`)
- **Arrays**: plural PascalCase (`$Nodes`, `$Vservers`)
- Use `?? '--'` for null-coalescing to display placeholder in tables

### Formatting (enforced by `.vscode/settings.json`)

- 4-space indentation (no tabs)
- Opening brace on the same line (`if ($x) {`)
- Whitespace around operators, pipes, and separators
- Max line length: 115 characters
- No trailing whitespace
- Use full cmdlet names (no aliases — `ForEach-Object`, not `%`)
- Use correct casing for cmdlets (`Get-NcCluster`, not `get-nccluster`)

### PScribo Patterns

- `Section` / `Heading1`-`Heading5` for document structure
- `Table` with `ColumnWidths` always summing to 100
- `Set-Style` values: `OK`, `Warning`, `Critical`, `Info`
- `List = $true` for single-object detail views; `List = $false` for multi-row tables
- Always wrap table creation in `if ($Report.ShowTableCaptions)` before setting `Caption`

### Error Handling

- Wrap all data collection in `try/catch`
- Use `Write-PScriboMessage -IsWarning $_.Exception.Message` to log errors without aborting the report
- Non-fatal: missing data should result in the section being silently skipped (check with `if ($Data)`)

## Key Dependencies

| Module | Version | Role |
|---|---|---|
| `AsBuiltReport.Core` | ≥ 1.6.2 | Framework, PScribo integration |
| `NetApp.ONTAP` | ≥ 9.18.1.2601 | ONTAP API cmdlets (`Get-Nc*`) |
| `AsBuiltReport.Diagram` | ≥ 1.0.3 | Topology diagram generation |
| `AsBuiltReport.Chart` | ≥ 0.3.0 | Chart/graph generation |

Install all dependencies:

```powershell
Install-Module AsBuiltReport.Core, NetApp.ONTAP, AsBuiltReport.Diagram, AsBuiltReport.Chart
```
