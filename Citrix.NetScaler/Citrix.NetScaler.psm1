<#
    This is a work in progress module for the Citrix NetScaler.  It is currently limited to retrieving information from a NetScaler.
    My apologies for the messy code.  Will create a module manifest and straighten things out at some point.

    INSTRUCTIONS:
        (1) Run AutogenFunctions.ps1 with the appropriate arguments.  For more information, run Get-Help \\path\to\Citrix.NetScaler\AutogenFunctions.ps1
        (2) Copy resulting folder to an appropriate module location
        (3) Import-Module Citrix.NetScaler

    #QUICKSTART
        # WARNING: generates 900 + functions, sends credentials in the clear!
        & "\\path\to\Citrix.NetScaler\AutogenFunctions.ps1" -Address YourNetScalerAddressHere -AllowHTTPAuth

    #OTHER EXAMPLES

        #1 Limit all functions to address "ctx-ns-tst-02", "ctx-ns-tst-01", set default address to "ctx-ns-tst-01" (WARNING: generates 900 + functions, sends credentials in the clear!)
            & \\path\to\Citrix.NetScaler\AutogenFunctions.ps1 -address "CTX-NS-TST-02" -AllowHTTPAuth -allNetScalerAddresses "ctx-ns-tst-02", "ctx-ns-tst-01" -defaultNetScalerAddress "ctx-ns-tst-01"
        
        #2 Limit all functions to address "ctx-ns-tst-02", "ctx-ns-tst-01", set default address to "ctx-ns-tst-01", ONLY create functions for server, lbvserver, service, servicegroup, and ns objects (WARNING: sends credentials in the clear!)
        & \\path\to\Citrix.NetScaler\AutogenFunctions.ps1 -address "CTX-NS-TST-02" -AllowHTTPAuth -allNetScalerAddresses "ctx-ns-tst-02", "ctx-ns-tst-01" -defaultNetScalerAddress "ctx-ns-tst-01" -FunctionList server, lbvserver, service, servicegroup, ns

            \\path\to\Citrix.NetScaler\AutogenFunction files created:
                Get-NSlbvserverConfig
                Get-NSlbvserverStat
                Get-NSnsStat
                Get-NSserverConfig
                Get-NSserviceConfig
                Get-NSservicegroupConfig
                Get-NSservicegroupStat
                Get-NSserviceStat

    
    
            
#>

#Get the current directory, define subfolders.
$ModPath = split-path -parent $MyInvocation.MyCommand.Definition
$foldersToImport = "Functions", "AutogenFunctions"

#Get all ps1 files to import
$files = foreach($folder in $foldersToImport)
{
    $folder = Join-Path $ModPath $folder
    if(test-path $folder -ErrorAction SilentlyContinue)
    {
        Get-ChildItem $folder -Filter *.ps1 | select -ExpandProperty fullname
    }
    else
    {
        if($folder -eq "Functions")
        {
            Throw "Expected '$folder'.  Where is it?"
            Break
        }
        else
        {
            Write-Warning "AutogenFunctions folder not found.`nOnly imported base functions.`nRead instructions for details on auto-generating functions or run Get-Help '$ModPath\AutogenFunctions.ps1' -full"
        }
        
    }
}

#Import the PS1 files
foreach($file in $files)
{
    . "$file"
}