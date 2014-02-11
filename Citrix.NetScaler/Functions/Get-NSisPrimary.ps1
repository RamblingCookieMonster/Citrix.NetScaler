Function Get-NSisPrimary {
    <#
    .SYNOPSIS
        Get the current HA state for a NetScaler

    .PARAMETER Address
        Hostname for the NetScaler

    .PARAMETER Credential
        PSCredential object to authenticate with NetScaler.  Prompts if you don't provide one.

    .PARAMETER WebSession
        If specified, use an existing web session rather than an explicit credential
    
    .PARAMETER Bool
        If specified, return $true for Primary, $false for anything else

    .PARAMETER Raw
        If specified, don't select ns from Invoke-RESTMethod command

    .PARAMETER AllowHTTPAuth
        Allow HTTP.  Don't specify this uless you want authentication data to potentially be sent in clear text

    .PARAMETER TrustAllCertsPolicy
        Sets your [System.Net.ServicePointManager]::CertificatePolicy to trust all certificates.  Remains in effect for the rest of the session.  See .\Functions\Set-TrustAllCertsPolicy.ps1 for details.  On by default

    .EXAMPLE
        #$true or $false depending on whether ctx-ns-tst-01 is the primary in an HA cluster
            Get-NSisPrimary -Address ctx-ns-tst-01 -bool -AllowHTTPAuth -session $session

    .EXAMPLE
        #Displays Primary or Secondary depending on whether ctx-ns-tst-01 is the primary or secondary in an HA cluster
            Get-NSisPrimary -Address ctx-ns-tst-01 -AllowHTTPAuth -session $session

    .FUNCTIONALITY
        NetScaler
    #>
    [cmdletbinding()]
    param(
    
        [string]$Address = $null,

        [System.Management.Automation.PSCredential]$Credential = $null,

        [Microsoft.PowerShell.Commands.WebRequestSession]$WebSession = $null,

        [switch]$bool = $null,

        [switch]$Raw,

        [switch]$AllowHTTPAuth,

        [bool]$TrustAllCertsPolicy = $true

    )

    #Run Set-TrustAllCertsPolicy unless otherwise specified.
    if( $TrustAllCertsPolicy )
    {
        Set-TrustAllCertsPolicy
    }

    #Define the URI
    $uri = "https://$address/nitro/v1/stat/ns/"
    
    if($ns){
        $uri += $ns
    }
    
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
        $result = $null
        $result = $(
            Try
            {
                Invoke-RestMethod @IRMParam
            }
            Catch
            {
                write-warning "Error calling Invoke-RESTMethod: $_"
                if($AllowHTTPAuth)
                {
                    Try
                    {
                        Write-Verbose "Reverting to HTTP"
                        $IRMParam["uri"] = $uri -replace "^https","http"
                        Invoke-RestMethod @IRMParam
                    }
                    Catch
                    {
                        Throw "Fallback to HTTP Failed: $_"
                        break
                    }

                }
            }
        )

    #Take action depending on -raw parameter and the data in $result
        if($result)
        {
            #Result exists and user wants raw output
            if($Raw)
            {
                $result
            }
            #Result exists with no error
            elseif($result.errorcode -eq 0)
            {
                $hacurmasterstate = $result | select -ExpandProperty ns | select -ExpandProperty hacurmasterstate

                if($bool)
                {
                    if($hacurmasterstate -like "Primary")
                    {
                        $true
                    }
                    else
                    {
                        $false
                    }

                }
                else
                {
                    $hacurmasterstate
                }
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
