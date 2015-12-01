Function Add-NSserverconfig {
    <#
    .SYNOPSIS
        Create a server on a NetScaler

    .DESCRIPTION
        Create a server on a NetScaler

    .PARAMETER Address
        Hostname for the NetScaler

    .PARAMETER AllowHTTPAuth
        Allow HTTP.  Don't specify this uless you want authentication data to potentially be sent in clear text

    .PARAMETER TrustAllCertsPolicy
        Sets your [System.Net.ServicePointManager]::CertificatePolicy to trust all certificates.  Remains in effect for the rest of the session.  See .\Functions\Set-TrustAllCertsPolicy.ps1 for details.  On by default

    .FUNCTIONALITY
        NetScaler

    .EXAMPLE
        #Provide parameters register new server on a netsacler
            Add-NSserverconfig -Address CTX-NS-01 -vname vmhostname -hostip 1.1.1.10 -srvuser "service username" -srvpass "password to user service" -AllowHTTPAuth

     #>   
[cmdletbinding()]
    param(
        [validateset("CTX-NS-01","CTX-NS-02","CTX-NS-03","CTX-NS-04")]
        [string]$Address = "CTX-NS-01",
        [Parameter(Mandatory=$False,Position=0)][string]$vname,
        [Parameter(Mandatory=$False,Position=1)][string]$hostip,
        [Parameter(Mandatory=$False,Position=2)][string]$srvuser,
        [Parameter(Mandatory=$False,Position=3)][string]$srvpass,
	    [switch]$Raw,
	    [switch]$AllowHTTPAuth,
        [bool]$TrustAllCertsPolicy = $true

    )

    if( $TrustAllCertsPolicy )
    {
        SetTrustAllCertsPolicy
    }

#Define parameters
    $uri = "https://$address/nitro/v1/config/server?action=add"
    $conT = "application/vnd.com.citrix.netscaler.server+json"
    $username = "${srvuser}"
    $password = "${srvpass}"
    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username,$password)))

#Build the login json
$jsonCred = @"
{
    "server": {
        "name": "$vname",
        "ipaddress": "$hostip"
    }
}
"@

    #Build parameters for Invoke-RESTMethod
        $IRMParam = @{
            Uri = $uri
            Method = "Post"
            Body = $jsonCred
            ContentType = $conT
            Headers = @{Authorization=("Basic {0}" -f $base64AuthInfo)}
            ErrorAction = "Stop"
        }

     Write-Verbose "Running Invoke-RESTMethod with these parameters:`n$($IRMParam | Format-Table -AutoSize -wrap)"
     $result = $null
     $reghost = $null
     $reghost = try
        {
        $result = CallInvokeRESTMethod -IRMParam $IRMParam -AllowHTTPAuth $AllowHTTPAuth -ErrorAction Stop
	    Write-Host -ForegroundColor Green "Task to create server $hostip $vname is done."
         }
         Catch
                     {
                
                if($AllowHTTPAuth)
                {
                    Try
                    {
                        Write-Verbose "Reverting to HTTP"
                        $IRMParam["URI"] = $IRMParam["URI"] -replace "^https","http"
                        $result = CallInvokeRESTMethod -IRMParam $IRMParam -AllowHTTPAuth $AllowHTTPAuth -ErrorAction Stop
                    }
                    Catch
                    {
                        Throw "Fallback to HTTP Failed: $_"
                        break
                    }
                }
            }

        if($result)
        {
            if($raw)
            {
                $result
            }
            elseif($reghost.errorcode -eq 0)
            {
                $result
            }
            else
            {
                Write-Error "Something went wrong.  Full Invoke-RESTMethod output:"
            }
        }

}
