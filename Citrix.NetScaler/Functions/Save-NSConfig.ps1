Function Save-NSConfig {
    <#
    .SYNOPSIS
        Saves the running config for a NetScaler

    .PARAMETER Address
        Hostname for the NetScaler

    .PARAMETER WebSession
        If specified, use an existing web session rather than an explicit credential

    .PARAMETER Force
        If specified do not check to ensure NetScaler is primary in the HA cluster

        I recall this might not be best practice, but currently if you want to bypass confirmation you need to use -confirm:$false

    .PARAMETER AllowHTTPAuth
        Allow HTTP.  Don't specify this uless you want authentication data to potentially be sent in clear text

    .PARAMETER TrustAllCertsPolicy
        Sets your [System.Net.ServicePointManager]::CertificatePolicy to trust all certificates.  Remains in effect for the rest of the session.  See .\Functions\Set-TrustAllCertsPolicy.ps1 for details.  On by default

    .EXAMPLE
        #Get a session on CTX-NS-TST-02, save the config
            $session = Get-NSSessionCookie -Address ctx-ns-tst-02
            Save-NSConfig -Verbose -WebSession $session -Address ctx-ns-tst-02

    .FUNCTIONALITY
        NetScaler

    .LINK
        http://github.com/RamblingCookieMonster/Citrix.NetScaler
    #>
    [cmdletbinding(
        SupportsShouldProcess=$true,
        ConfirmImpact='High'
    )]
    param(
    
        $Address = "CTX-NS-TST-01",

        [Microsoft.PowerShell.Commands.WebRequestSession]$WebSession = $null,

        [switch]$Force,

        [switch]$AllowHTTPAuth,

        [bool]$TrustAllCertsPolicy = $true

    )

    #Run Set-TrustAllCertsPolicy unless otherwise specified.
    if( $TrustAllCertsPolicy )
    {
        SetTrustAllCertsPolicy
    }
        
    #If no credential or web session is provided, get a credential
        if(-not $WebSession)
        {
            Write-Error "No WebSession provided.  Please run Get-Help Get-NSSessionCookie -full for more information."
            Break
        }

    #We want to verify we are running against the primary NS
        $GetPrimaryParam = @{
            Address = $Address
            ErrorAction = 'stop'
            WebSession = $WebSession
        }
        If($AllowHTTPAuth)
        {
            $GetPrimaryParam.Add("AllowHTTPAuth",$true)
        }

    #Build parameters for Invoke-RESTMethod
        $IRMParam = @{
            uri = "https://$address/nitro/v1/config/nsconfig?action=save"
            Body = ‘{“nsconfig”:{}}’
            Method = 'Post'
            ContentType = 'application/vnd.com.citrix.netscaler.nsconfig+json'
            ErrorAction = 'Stop'
            WebSession = $WebSession
        }
    

    $HAState = Get-NSisPrimary @GetPrimaryParam
    Write-Verbose "HAState is $HAState"

    If( $HAState -eq 'primary' -or $force )
    {

        #Collect results
            if ($pscmdlet.ShouldProcess("$Address", "Save running configuration state"))
            {
                $result = $null
                $result = CallInvokeRESTMethod -IRMParam $IRMParam -AllowHTTPAuth $AllowHTTPAuth -ErrorAction Stop
            
                #Take action depending on -raw parameter and the data in $result
                    if($result)
                    {

                        #Result exists with no error
                        if($result.errorcode -ne 0)
                        {
                            Write-Error "Something went wrong.  Full Invoke-RESTMethod output: `n"
                            $result
                        }
                    }
                    else
                    {
                        Write-Verbose "Invoke-RESTMethod output was empty.  This is the expected behavior"
                    }
            }
    }
    elseif(-not $force)
    {   
        Throw "$Address is set as the '$HAState' node.  Pick the Primary node or use the force parameter"
    }
}
