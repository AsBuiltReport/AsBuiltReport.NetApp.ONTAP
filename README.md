<p align="center">
    <a href="https://www.asbuiltreport.com/" alt="AsBuiltReport"></a>
            <img src='https://avatars.githubusercontent.com/u/42958564' width="8%" height="8%" /></a>
</p>
<p align="center">
    <a href="https://www.powershellgallery.com/packages/AsBuiltReport.NetApp.ONTAP/" alt="PowerShell Gallery Version">
        <img src="https://img.shields.io/powershellgallery/v/AsBuiltReport.NetApp.ONTAP.svg" /></a>
    <a href="https://www.powershellgallery.com/packages/AsBuiltReport.NetApp.ONTAP/" alt="PS Gallery Downloads">
        <img src="https://img.shields.io/powershellgallery/dt/AsBuiltReport.NetApp.ONTAP.svg" /></a>
    <a href="https://www.powershellgallery.com/packages/AsBuiltReport.NetApp.ONTAP/" alt="PS Platform">
        <img src="https://img.shields.io/powershellgallery/p/AsBuiltReport.NetApp.ONTAP.svg" /></a>
</p>
<p align="center">
    <a href="https://github.com/AsBuiltReport/AsBuiltReport.NetApp.ONTAP/graphs/commit-activity" alt="GitHub Last Commit">
        <img src="https://img.shields.io/github/last-commit/AsBuiltReport/AsBuiltReport.NetApp.ONTAP/master.svg" /></a>
    <a href="https://raw.githubusercontent.com/AsBuiltReport/AsBuiltReport.NetApp.ONTAP/master/LICENSE" alt="GitHub License">
        <img src="https://img.shields.io/github/license/AsBuiltReport/AsBuiltReport.NetApp.ONTAP.svg" /></a>
    <a href="https://github.com/AsBuiltReport/AsBuiltReport.NetApp.ONTAP/graphs/contributors" alt="GitHub Contributors">
        <img src="https://img.shields.io/github/contributors/AsBuiltReport/AsBuiltReport.NetApp.ONTAP.svg"/></a>
</p>
<p align="center">
    <a href="https://twitter.com/AsBuiltReport" alt="Twitter">
            <img src="https://img.shields.io/twitter/follow/AsBuiltReport.svg?style=social"/></a>
</p>
<p align="center">
    <a href='https://ko-fi.com/F1F8DEV80' target='_blank'><img height='36' style='border:0px;height:36px;' src='https://cdn.ko-fi.com/cdn/kofi1.png?v=3'            border='0' alt='Buy Me a Coffee at ko-fi.com' /></a>
</p>

# NetApp ONTAP Arrays AsBuiltReport

NetApp ONTAP As Built Report is a PowerShell module which works in conjunction with [AsBuiltReport.Core](https://github.com/AsBuiltReport/AsBuiltReport.Core).

[AsBuiltReport](https://github.com/AsBuiltReport/AsBuiltReport) is an open-sourced community project which utilises PowerShell to produce as-built documentation in multiple document formats for multiple vendors and technologies.

Please refer to the AsBuiltReport [website](https://www.asbuiltreport.com) for more detailed information about this project.

## :books: Sample Reports

### Sample Report - Custom Style 1

Sample NetApp ONTAP As Built report HTML file: [Sample NetApp As-Built Report.html](https://htmlpreview.github.io/?https://raw.githubusercontent.com/AsBuiltReport/AsBuiltReport.NetApp.ONTAP/dev/Samples/Sample%20NetApp%20As-Built%20Report.html)

# :beginner: Getting Started

Below are the instructions on how to install, configure and generate a NetApp ONTAP As Built Report

## :floppy_disk: Supported Versions

### **NetApp / ONTAP**

The ONTAP Storage As Built Report supports the following ONTAP versions;

- ONTAP 9.x
  - Tested on v9.5, 9.7, 9.8, 9.9.1, 9.10.1, 9.11.1, 9.12.1, 9.13.1, 9.14.1, 9.15.1

### **PowerShell**

This report is compatible with the following PowerShell versions;

|   PowerShell 5.1   |    PowerShell 7    |
| :----------------: | :----------------: |
| :white_check_mark: | :white_check_mark: |

## :wrench: System Requirements

Each of the following modules will be automatically installed by following the [module installation](https://github.com/AsBuiltReport/AsBuiltReport.NetApp.ONTAP#package-module-installation) procedure.

These modules may also be manually installed.

| Module Name        | Minimum Required Version |                              PS Gallery                               |                                   GitHub                                    |
|--------------------|:------------------------:|:---------------------------------------------------------------------:|:---------------------------------------------------------------------------:|
| PScribo            |          0.10.0           |      [Link](https://www.powershellgallery.com/packages/PScribo)       |         [Link](https://github.com/iainbrighton/PScribo/tree/master)         |
| AsBuiltReport.Core |          1.4.0           | [Link](https://www.powershellgallery.com/packages/AsBuiltReport.Core) | [Link](https://github.com/AsBuiltReport/AsBuiltReport.Core/releases/latest) |
| Netapp.ONTAP |          9.15.1.2407           | [Link](https://www.powershellgallery.com/packages/NetApp.ONTAP) |  |

## :package: Module Installation

### PowerShell

Open a PowerShell terminal window and install each of the required modules as follows;

```powershell
Install-Module -Name AsBuiltReport.NetApp.ONTAP
```

### GitHub

If you are unable to use the PowerShell Gallery, you can still install the module manually. Ensure you repeat the following steps for the [system requirements](https://github.com/AsBuiltReport/AsBuiltReport.NetApp.ONTAP#wrench-system-requirements) also.

1. Download the code package / [latest release](https://github.com/AsBuiltReport/AsBuiltReport.NetApp.ONTAP/releases/latest) zip from GitHub
2. Extract the zip file
3. Copy the folder `AsBuiltReport.NetApp.ONTAP` to a path that is set in `$env:PSModulePath`.
4. Open a PowerShell terminal window and unblock the downloaded files with

    ```powershell
    $path = (Get-Module -Name AsBuiltReport.NetApp.ONTAP -ListAvailable).ModuleBase; Unblock-File -Path $path\*.psd1; Unblock-File -Path $path\Src\Public\*.ps1; Unblock-File -Path $path\Src\Private\*.ps1
    ```

5. Close and reopen the PowerShell terminal window.

_Note: You are not limited to installing the module to those example paths, you can add a new entry to the environment variable PSModulePath if you want to use another path._

### :closed_lock_with_key: Required Privileges

To generate a NetApp ONTAP Array report, a user account with the readonly role of higher on the AFF/FAS is required.

## :pencil2: Configuration

The NetApp ONTAP Array As Built Report utilises a JSON file to allow configuration of report information, options, detail and healthchecks.

A NetApp ONTAP Array report configuration file can be generated by executing the following command;

```powershell
New-AsBuiltReportConfig -Report NetApp.ONTAP -FolderPath <User specified folder> -FileName <Optional>
```

Executing this command will copy the default ONTAP report JSON configuration to a user specified folder.

All report settings can then be configured via the JSON file.

The following provides information of how to configure each schema within the report's JSON file.

### Report

The **Report** schema provides configuration of the NetApp ONTAP report information.

| Sub-Schema          | Setting      | Default                      | Description                                                  |
| ------------------- | ------------ | ---------------------------- | ------------------------------------------------------------ |
| Name                | User defined | NetApp ONTAP As Built Report | The name of the As Built Report                              |
| Version             | User defined | 1.0                          | The report version                                           |
| Status              | User defined | Released                     | The report release status                                    |
| ShowCoverPageImage  | true / false | true                         | Toggle to enable/disable the display of the cover page image |
| ShowTableOfContents | true / false | true                         | Toggle to enable/disable table of contents                   |
| ShowHeaderFooter    | true / false | true                         | Toggle to enable/disable document headers & footers          |
| ShowTableCaptions   | true / false | true                         | Toggle to enable/disable table captions/numbering            |

### Options

The **Options** schema allows certain options within the report to be toggled on or off.
| Sub-Schema            | Setting      | Default | Description                                        |
| --------------------- | ------------ | ------- | -------------------------------------------------- |
| Exclude: Vserver      | Array List   | Empty   | Allow to filter on Vserver Name                    |
| Exclude: MetroCluster | true / false | false   | Allow to filter automatically all Vserver with -mc |

### InfoLevel

The **InfoLevel** schema allows configuration of each section of the report at a granular level. The following sections can be set.

There are 3 levels (0-2) of detail granularity for each section as follows;

| Setting | InfoLevel         | Description                                                          |
| :-----: | ----------------- | -------------------------------------------------------------------- |
|    0    | Disabled          | Does not collect or display any information                          |
|    1    | Enabled / Summary | Provides summarised information for a collection of objects          |
|    2    | Adv Summary       | Provides condensed, detailed information for a collection of objects |

The table below outlines the default and maximum **InfoLevel** settings for each section.

| Sub-Schema  | Default Setting | Maximum Setting |
| ----------- | :-------------: | :-------------: |
| Cluster     |        1        |        2        |
| Node        |        1        |        2        |
| Storage     |        1        |        2        |
| Network     |        1        |        2        |
| License     |        1        |        2        |
| Vserver     |        1        |        2        |
| Efficiency  |        1        |        2        |
| Security    |        1        |        2        |
| System      |        1        |        2        |
| Replication |        1        |        2        |

### Healthcheck

The **Healthcheck** schema is used to toggle health checks on or off.

## :computer: Examples

There are a few examples listed below on running the AsBuiltReport script against a NetApp ONTAP Array target. Refer to the `README.md` file in the main AsBuiltReport project repository for more examples.

```powershell
# Generate a NetApp ONTAP As Built Report for Cluster array '192.168.7.60' using specified credentials. Export report to HTML & DOCX formats. Use default report style. Append timestamp to report filename. Save reports to 'C:\Users\Jon\Documents'
PS C:\> New-AsBuiltReport -Report NetApp.ONTAP -Target 192.168.7.60 -Username 'admin' -Password 'P@ssw0rd' -Format Html,Word -OutputFolderPath 'C:\Users\Jon\Documents' -Timestamp

# Generate a NetApp ONTAP As Built Report for Cluster array 192.168.7.60 using specified credentials and report configuration file. Export report to Text, HTML & DOCX formats. Use default report style. Save reports to 'C:\Users\Jon\Documents'. Display verbose messages to the console.
PS C:\> New-AsBuiltReport -Report NetApp.ONTAP -Target 192.168.7.60 -Username 'admin' -Password 'P@ssw0rd' -Format Text,Html,Word -OutputFolderPath 'C:\Users\Jon\Documents' -ReportConfigFilePath 'C:\Users\Jon\AsBuiltReport\AsBuiltReport.NetApp.ONTAP.json' -Verbose

# Generate a NetApp ONTAP As Built Report for Cluster array 192.168.7.60 using stored credentials. Export report to HTML & Text formats. Use default report style. Highlight environment issues within the report. Save reports to 'C:\Users\Jon\Documents'.
PS C:\> $Creds = Get-Credential
PS C:\> New-AsBuiltReport -Report NetApp.ONTAP -Target 192.168.7.60 -Credential $Creds -Format Html,Text -OutputFolderPath 'C:\Users\Jon\Documents' -EnableHealthCheck

# Generate a NetApp ONTAP As Built Report for Cluster array 192.168.7.60 using stored credentials. Export report to HTML & DOCX formats. Use default report style. Reports are saved to the user profile folder by default. Attach and send reports via e-mail.
PS C:\> New-AsBuiltReport -Report NetApp.ONTAP -Target 192.168.7.60 -Username 'admin' -Password 'P@ssw0rd' -Format Html,Word -OutputFolderPath 'C:\Users\Jon\Documents' -SendEmail

```
## :x: Known Issues

- There are known issues with the NetApp.ONTAP module v9.11.1.2208. Therefore, v9.10.1.2111 is the recommended module version.
