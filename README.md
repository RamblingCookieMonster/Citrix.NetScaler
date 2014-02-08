Citrix.NetScaler
================

PowerShell module for working with Citrix NetScaler REST API

INSTRUCTIONS:
    (0) Place the Citrix.NetScaler folder somewhere on your system
    (1) Run AutogenFunctions.ps1 with the appropriate arguments.
        NOTE:  For more information, run Get-Help \\path\to\Citrix.NetScaler\AutogenFunctions.ps1
    (2) Copy resulting folder to an appropriate module location
    (3) Import-Module Citrix.NetScaler
        
        
Further References
 
* http://blogs.citrix.com/2011/08/05/nitro-apis-fun-over-http/
* http://support.citrix.com/proddocs/topic/netscaler-main-api-10-map/ns-nitro-rest-landing-page-con.html
* http://support.citrix.com/servlet/KbServlet/download/30602-102-681756/NS-Nitro-Gettingstarted-guide.pdf
* http://blogs.citrix.com/2014/02/04/using-curl-with-the-netscaler-nitro-rest-api/
* There is no NetScaler REST API documentation available online.  It is tucked deep in the NetScaler bits.  If you have the bits for 10.1, extract them from here:  build-10.1-119.7_nc.tgz\build_dara_119_7_nc.tar\ns-10.1-119.7-nitro-rest.tgz\ns-10.1-119.7-nitro-rest.tar\ns_nitro-rest_dara_119_7.tar\
* My first stab at this is published in the TechNet Gallery, might be more information there:  http://gallery.technet.microsoft.com/scriptcenter/Invoke-NSCustomQuery-67dd27b5