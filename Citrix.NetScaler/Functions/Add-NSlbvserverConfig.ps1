Function Add-NSlbvserverConfig {
    <#
    .SYNOPSIS
        Add lbvservers on a NetScaler

    .PARAMETER Address
        Hostname for the NetScaler

    .PARAMETER lbvserver
        Specific lbvserver name to query for

    .PARAMETER Raw
        If specified, don't select lbvserver from Invoke-RESTMethod command

    .PARAMETER AllowHTTPAuth
        Allow HTTP.  Don't specify this uless you want authentication data to potentially be sent in clear text

    .PARAMETER TrustAllCertsPolicy
        Sets your [System.Net.ServicePointManager]::CertificatePolicy to trust all certificates.  Remains in effect for the rest of the session.  See .\Functions\Set-TrustAllCertsPolicy.ps1 for details.  On by default

    .EXAMPLE
        #Explore all properties for lbvserver SomeValidlbvserver on CTX-NS-01
        Add-NSconfiglbvserver -Address CTX-NS-01 -lbname product -lbservice HTTP -lbvipaddress 1.1.2.1 -lbport 80 -lbmethod roundrobin -lbenv QA -comment "comment it" -AllowHTTPAuth

    .FUNCTIONALITY
        NetScaler

    #>
    [cmdletbinding()]
    param(
    
        [validateset("CTX-NS-01","CTX-NS-02","CTX-NS-03","CTX-NS-04")]
        [string]$Address = "CTX-NS-01",
        [Parameter(Mandatory=$False,Position=0)][string]$lbname,
        [Parameter(Mandatory=$False,Position=1)][string]$lbservice,
        [Parameter(Mandatory=$False,Position=2)][string]$lbvipaddress,
        [Parameter(Mandatory=$False,Position=3)][string]$lbport,
        [Parameter(Mandatory=$False,Position=4)][string]$lbmethod,
        [Parameter(Mandatory=$False,Position=5)][string]$lbenv,
        [Parameter(Mandatory=$False,Position=1)][string]$srvuser,
        [Parameter(Mandatory=$False,Position=1)][string]$srvpass,
        [Parameter(Mandatory=$False,Position=6)][string]$comment,
        [switch]$Raw,
        [switch]$AllowHTTPAuth,
        [bool]$TrustAllCertsPolicy = $true
    )

    #Run Set-TrustAllCertsPolicy unless otherwise specified.
    if( $TrustAllCertsPolicy )
    {
        SetTrustAllCertsPolicy
    }

    #Define the URI
    $uri = "https://$address/nitro/v1/config/lbvserver?action=add"
    $conT = "application/vnd.com.citrix.netscaler.lbvserver"
    $username = "${srvuser}"
    $password = "${srvpass}"
    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username,$password)))

    $vserver="VIP_${lbname}_${lbenv}_${lbport}"

$jsonlbvsercer = @"
{
    "lbvserver":
       {
        "name”:”$vserver",
        "servicetype":"$lbservice",
        "ipv46":"$lbvipaddress",
        "port":"$lbport",
        "lbmethod":"$lbmethod",
	      "comment":"Create by: $comment"
       }
}
"@

    #Build up invoke-Restmethod parameters based on input
        $IRMParam = @{
            Uri = $uri
            Method = "Post"
            Body = $jsonlbvsercer
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
            Write-Host -ForegroundColor Green "Task to create lbvserver: ${vserver}, ${lbservice} and $lbvipaddress is done."
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
