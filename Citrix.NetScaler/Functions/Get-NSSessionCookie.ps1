Function Get-NSSessionCookie
{
    <#
    .SYNOPSIS
        Create a session on a NetScaler

    .DESCRIPTION
        Create a session on a NetScaler

    .PARAMETER Address
        Hostname for the NetScaler

    .PARAMETER Credential
        PSCredential object to authenticate with NetScaler.  Prompts if you don't provide one.

    .PARAMETER Timeout
        Timeout for session in seconds

    .PARAMETER AllowHTTPAuth
        Allow HTTP.  Don't specify this uless you want authentication data to potentially be sent in clear text

    .PARAMETER TrustAllCertsPolicy
        Sets your [System.Net.ServicePointManager]::CertificatePolicy to trust all certificates.  Remains in effect for the rest of the session.  See .\Functions\Set-TrustAllCertsPolicy.ps1 for details.  On by default

    .FUNCTIONALITY
        NetScaler

    .LINK
        http://github.com/RamblingCookieMonster/Citrix.NetScaler
    #>
    [cmdletbinding()]
    param
    (

        $Address = "CTX-NS-TST-01",

        [System.Management.Automation.PSCredential]$Credential = $( Get-Credential -Message "Provide credentials for $Address" ),

        [int]$Timeout = 3600,

        [switch]$AllowHTTPAuth,

        [bool]$TrustAllCertsPolicy = $true

    )

    if( $TrustAllCertsPolicy )
    {
        SetTrustAllCertsPolicy
    }

    #Define the URI
    $uri = "https://$address/nitro/v1/config/login/"
    
    #Extract the username, take into account domain names
    If($Credential -match "\\")
    {
        $user = $Credential.username.split("\")[1]
    }
    Else
    {
        $user = $Credential.username.split("\")[0]
    }

    #Build the login json
    $jsonCred = @"
{
    "login":  {
                  "username":  "$user",
                  "password":  "$($Credential.GetNetworkCredential().password)",
                  "timeout": $timeout
              }
}
"@

    #Build parameters for Invoke-RESTMethod
    $IRMParam = @{
        Uri = $uri
        Method = "Post"
        Body = $jsonCred
        ContentType = "application/json"
        SessionVariable = "sess"
    }
    
    #Invoke the REST Method to get a cookie using 'SessionVariable'
        Write-Verbose "Running Invoke-RESTMethod with these parameters:`n$($IRMParam | Format-Table -AutoSize -wrap | Out-String)"
        $cookie = $null
        $cookie = Try
            {
                Invoke-RestMethod @IRMParam
            }
    
            Catch
            {
                Write-Warning "Error calling Invoke-RESTMethod.  Fall back to HTTP=$AllowHTTPAuth. Error details:`n $_"
                if($AllowHTTPAuth)
                {
                    Try
                    {
                        Write-Verbose "Reverting to HTTP"
                        $IRMParam["URI"] = $IRMParam["URI"] -replace "^https","http"
                        Invoke-RestMethod @IRMParam
                    }
                    Catch
                    {
                        Throw "Fallback to HTTP Failed: $_"
                        break
                    }
                }
            }

    if($cookie)
    {
        #If we got a session variable, return it.  Otherwise, display the results in a warning
        if($sess)
        {
            #Provide feedback on expiration
            $date = ( get-date ).AddSeconds($Timeout)
            Write-Verbose "Cookie set to expire in '$Timeout' seconds, at $date"
            $sess
        }
        else
        {
            Write-Warning "No session created.  Invoke-RESTMethod output:`n$( $cookie | Format-Table -AutoSize -Wrap | Out-String )"
        }
    }
    else{
        Write-Error "Invoke-RESTMethod output was empty.  Try troubleshooting with -verbose switch"
    }
}
