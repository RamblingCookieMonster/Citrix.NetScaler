Citrix.NetScaler
================

This is a work in progress module for working with the Citrix NetScaler REST API.  It is currently limited to creating sessions on and retrieving information from a NetScaler.  Individual functions can be automatically created with the AutogenFunctions script.

# Instructions

1. Download this repo, Unblock the file(s), copy the Citrix.NetScaler to an appropriate module location
2. Run Citrix.NetScaler\AutogenFunctions.ps1 with the appropriate arguments to generate functions.
  * NOTE:  For more information, run Get-Help \\path\to\Citrix.NetScaler\AutogenFunctions.ps1
  * NOTE:  You may skip this step until later if desired.  Details in example.
4. Import-Module Citrix.NetScaler
        
# Autogenerating Functions

Here are a few examples on how you might run the autogenfuntions.ps1 script

    # Quick and Dirty!
		    # WARNING: generates all 900 + functions, sends credentials in the clear
        & "\\path\to\Citrix.NetScaler\AutogenFunctions.ps1" -Address YourNetScalerAddressHere -AllowHTTPAuth
   
    # Explore first
        #Import the module
        Import-Module "\\path\to\Citrix.NetScaler"
				
        #Create a session on CTX-NS-TST-01, get a list of config objects
        #WARNING: creds sent in clear text when using AllowHTTPAuth
        $session = Get-NSSessionCookie -Address ctx-ns-tst-01 -AllowHTTPAuth
        Get-NSObjectList -Address ctx-ns-tst-01 -WebSession $session -ObjectType config -AllowHTTPAuth
				    
        # From the list of objects, we decide we care about only a few...
        # Limit all functions to the address set "ctx-ns-tst-02", "ctx-ns-tst-01", set default address to "ctx-ns-tst-01", ONLY create functions for server, lbvserver, service, servicegroup, and ns objects
        # WARNING: sends credentials in the clear!
        & \\path\to\Citrix.NetScaler\AutogenFunctions.ps1 -address "CTX-NS-TST-02" -AllowHTTPAuth -allNetScalerAddresses "ctx-ns-tst-02", "ctx-ns-tst-01" -defaultNetScalerAddress "ctx-ns-tst-01" -FunctionList server, lbvserver, service, servicegroup, ns

After running the last example, the following files are available in \\path\to\Citrix.NetScaler\AutogenFunction:
* Get-NSlbvserverConfig
* Get-NSlbvserverStat
* Get-NSnsStat
* Get-NSserverConfig
* Get-NSserviceConfig
* Get-NSservicegroupConfig
* Get-NSservicegroupStat
* Get-NSserviceStat

# Using the Citrix.NetScaler module

    #Import the module!
    Import-Module Citrix.NetScaler
    
    #Get commands from the module.  Output below is from the second autogenerating example:
    Get-Command -Module Citrix.Netscaler | Select -ExpandProperty Name
        <#
            Get-NSlbvserverConfig
            Get-NSlbvserverStat
            Get-NSnsStat
            Get-NSObjectList
            Get-NSserverConfig
            Get-NSserviceConfig
            Get-NSservicegroupConfig
            Get-NSservicegroupStat
            Get-NSserviceStat
            Get-NSSessionCookie
            Set-TrustAllCertsPolicy
        #>
    
    #Create a session on CTX-NS-TST-01.  WARNING: creds sent in clear text when using AllowHTTPAuth!
        $session = Get-NSSessionCookie -Address ctx-ns-tst-01 -AllowHTTPAuth
    
    #Get a list of all config objects on CTX-NS-TST-01
        Get-NSObjectList -Address ctx-ns-tst-01 -WebSession $session -ObjectType config -AllowHTTPAuth
    
    #Get basic server config information
        Get-NSserverConfig -Address ctx-ns-tst-01 -WebSession $session -AllowHTTPAuth | select Name, State, Domain
        
        <#
            name        state   domain                  
            ----        -----   ------                  
            servername1 ENABLED servername1.domain.com
            servername1 ENABLED 
            ...
        #>
        
    #Get stats on services
    Get-NSserviceStat -Address ctx-ns-tst-01 -WebSession $session -AllowHTTPAuth | Select Name, numofconnections, servername,  servicetype, failedprobes | ft -AutoSize
    
    <#
        name             numofconnections servername servicetype failedprobes
        ----             ---------------- ---------- ----------- ------------
        svc_someservice1                0 servername1       HTTP            0           
        svc_someservice2                0 servername2       HTTP            0           
        ...
    #>

## Base Functions

These functions are available independent of the automatic generation of functions. 

### Get-NSSessionCookie

This command creates a session on a Citrix NetScaler.  You can use this session until it expires for all the commands in this module, as well as any other REST API calls you run against that NetScaler.

### Get-NSObjectList

This command retrieves a list of configuration (config) or statistical (stat) objects that NetScaler commands revolve around.  There are 876 configuration objects and 85 stat objects.  You can narrow these down when you call AutogenFunctions using the FunctionList argument.

## Property name bug:

If you get an error indicating  'select : Property "some property" cannot be found.', please use the -Raw switch on the command.

The issue is that in general, the NetScaler API returns the object type name (ns).  In some cases, it does not do this.  e.g. The stat with the name ns returns nstrace, instead of ns.

    #I get an error from command below:  'select : Property "ns" cannot be found.'
    Get-NSnsStat -Address ctx-ns-tst-01 -WebSession $session -AllowHTTPAuth
        
    #Adding the -raw switch, I can get the unadulterated Invoke-RESTMethod results, which include an nstrace property:
    Get-NSnsStat -Address ctx-ns-tst-01 -WebSession $session -AllowHTTPAuth -Raw
    
    #To extract the nstrace property, I would run this
    Get-NSnsStat -Address ctx-ns-tst-01 -WebSession $session -AllowHTTPAuth -Raw | Select -expandproperty nstrace

# TODO

* Functions for configuration changes; for example, Enable/Disabled/Add/Remove-LBVServer/Server, etc.
* Update [Invoke-NSCustomQuery](http://gallery.technet.microsoft.com/scriptcenter/Invoke-NSCustomQuery-67dd27b5) to leverage sessions and add functionality, add it to this module
* Further testing, improving existing functionality (e.g. rather than static response handling that breaks Get-NSnsStat, write dynamic response handling)
* Separate out autogeneration FunctionList argument so that Config and Stat functions can be chosen independently.  As is, 'service' pulls both Get-NSserviceConfig and Get-NSserviceStat
* Learn how to use GitHub
   
# Further References
 
* http://blogs.citrix.com/2011/08/05/nitro-apis-fun-over-http/
* http://support.citrix.com/proddocs/topic/netscaler-main-api-10-map/ns-nitro-rest-landing-page-con.html
* http://support.citrix.com/servlet/KbServlet/download/30602-102-681756/NS-Nitro-Gettingstarted-guide.pdf
* http://blogs.citrix.com/2014/02/04/using-curl-with-the-netscaler-nitro-rest-api/
* There is no NetScaler REST API documentation available online.  It is tucked deep in the NetScaler bits.  If you have the bits for 10.1, extract them from here:  build-10.1-119.7_nc.tgz\build_dara_119_7_nc.tar\ns-10.1-119.7-nitro-rest.tgz\ns-10.1-119.7-nitro-rest.tar\ns_nitro-rest_dara_119_7.tar\.  This should be available online at some point...
* My first stab at using this API is published in the TechNet Gallery, more information and screenshots with similar data can be [found here](http://gallery.technet.microsoft.com/scriptcenter/Invoke-NSCustomQuery-67dd27b5)

# Other notes

This is my first GitHub repo and second day (as of initial release) with the NetScaler REST API.  Please let me know if you have any suggestions or feedback!