cd C:\Dropbox\github\Citrix.NetScaler\Citrix.NetScaler
If (-not $c)
{
    $c = Get-Credential
}

Remove-Module Citrix.NetScaler
Import-Module .\Citrix.NetScaler.psd1


Connect-NSSession -Address nsmpx-12.athenahealth.com -Credential $c -Verbose

