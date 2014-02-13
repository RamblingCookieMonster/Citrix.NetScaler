Function Get-NSObjectList
{
    <#
    .SYNOPSIS
        Get servers on a NetScaler

    .PARAMETER Address
        Hostname for the NetScaler

    .PARAMETER Credential
        PSCredential object to authenticate with NetScaler

    .PARAMETER WebSession
        If specified, use an existing web session rather than an explicit credential

    .PARAMETER ObjectType
        Config or List

    .PARAMETER AllowHTTPAuth
        Allow HTTP.  Don't specify this uless you want authentication data to potentially be sent in clear text

    .PARAMETER TrustAllCertsPolicy
        Sets your [System.Net.ServicePointManager]::CertificatePolicy to trust all certificates.  Remains in effect for the rest of the session.  See .\Functions\Set-TrustAllCertsPolicy.ps1 for details.  On by default

    .EXAMPLE
        #Create a session on the NetScaler
            $session = Get-NSSessionCookie -Address "CTX-NS-TST-01"

        #Get all config objects on the NetScaler
            Get-NSObjectList -ObjectType Config -WebSession $session -Address "CTX-NS-TST-01"

    .EXAMPLE
        #Get stat object list from NetScaler, prompt for creds
            Get-NSObjectList -ObjectType Stat -Credential (Get-Credential) -Address "CTX-NS-TST-01"

    .FUNCTIONALITY
        NetScaler

    .LINK
        http://github.com/RamblingCookieMonster/Citrix.NetScaler
    #>
    [cmdletbinding()]
    param(

        $Address = "CTX-NS-TST-01",

        [System.Management.Automation.PSCredential]$Credential = $null,

        [Microsoft.PowerShell.Commands.WebRequestSession]$WebSession = $null,

        [validateset("config","stat")]
        [string]$ObjectType = "config",

        [switch]$AllowHTTPAuth,

        [bool]$TrustAllCertsPolicy = $true

    )

    #If no credential or web session is provided, get a credential
        if(-not $WebSession -and -not $Credential)
        {
            Write-Warning "No WebSession or Credential provided.  Please provide credentials"
            $Credential = $( Get-Credential -Message "Provide credentials for '$Address'" )
            if(-not $Credential)
            {
                break
            }
        }

    if( $TrustAllCertsPolicy )
    {
        SetTrustAllCertsPolicy
    }

    #Define the URI
        $uri = "https://$address/nitro/v1/$ObjectType/"

    #Build up invoke-Restmethod parameters based on input
        $IRMParam = @{
            Method = "Get"
            URI = $uri
            ErrorAction = "Stop" 
        }
        If($Credential)
        {
            $IRMParam.add("Credential",$Credential)
        }
        If($WebSession)
        {
            $IRMParam.add("WebSession",$WebSession)
        }

    #Collect results
        $result = CallInvokeRESTMethod -IRMParam $IRMParam -AllowHTTPAuth $AllowHTTPAuth -ErrorAction Stop
    
    #Expand out the list, or provide full response if we got an unexpected errorcode
        if($result)
        {
            if($result.errorcode -eq 0)
            {
                $result | select -ExpandProperty "$ObjectType`objects" | select -ExpandProperty objects
            }
            else
            {
                Write-Error "Something went wrong.  Full Invoke-RESTMethod output: `n"
                $result
            }
        }
        else{
            Write-Error "Invoke-RESTMethod output was empty.  Try troubleshooting with -verbose switch"
        }

}
