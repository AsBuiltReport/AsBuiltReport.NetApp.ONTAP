function Get-NetAppOntapAPI {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp ONTAP Rest API Calls from the Cluster Management Network
    .DESCRIPTION

    .NOTES
        Version:        0.6.7
        Author:         Tim Carman
        Editor:         Jonathan Colon
        Twitter:        @jcolonfzenpr
        Github:         rebelinux
    .EXAMPLE

    .LINK

    #>
    [CmdletBinding()]
    param (

        [Parameter(
            Mandatory = $true
        )]
        [ValidateNotNullOrEmpty()]
        [String] $uri
    )

    begin {
        #region Workaround for SelfSigned Cert an force TLS 1.2
        if (-not ([System.Management.Automation.PSTypeName]'ServerCertificateValidationCallback').Type) {
            $certCallback = @"
        using System;
        using System.Net;
        using System.Net.Security;
        using System.Security.Cryptography.X509Certificates;
        public class ServerCertificateValidationCallback
        {
            public static void Ignore()
            {
                if(ServicePointManager.ServerCertificateValidationCallback ==null)
                {
                    ServicePointManager.ServerCertificateValidationCallback +=
                        delegate
                        (
                            Object obj,
                            X509Certificate certificate,
                            X509Chain chain,
                            SslPolicyErrors errors
                        )
                        {
                            return true;
                        };
                }
            }
        }
"@
            Add-Type $certCallback
        }
        [ServerCertificateValidationCallback]::Ignore()
        [Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"
        #endregion Workaround for SelfSigned Cert an force TLS 1.2

        $username = $Credential.UserName
        $password = $Credential.GetNetworkCredential().Password
        $auth = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($username + ":" + $password ))
        $ClusterIP = $ClusterInfo.NcController.Address.IPAddressToString
        #$fields = 'fields=*&return_records=true&return_timeout=15'
        $api = "https://" + $($ClusterIP)
        $headers = @{
            'Accept' = 'application/json'
            'Authorization' = "Basic $auth"
            'Content-Type' = 'application/json'
        }
    }

    Process {
        Try {
            $response = Invoke-RestMethod -Method Get -Uri ($api + $uri) -Headers $headers -SkipCertificateCheck
            $response.records
        } Catch {
            Write-Verbose -Message $_
        }
    }

    End {}
}