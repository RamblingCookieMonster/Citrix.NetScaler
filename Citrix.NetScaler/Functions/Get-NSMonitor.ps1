Function Get-NSMonitor {
    <#
    .SYNOPSIS
        Get monitor objects for Citrix Netscaler
    .PARAMETER Name
        Filter on the name property, wildcards accepted
    .EXAMPLE
        Get-NSMonitor

        Retrieves all monitor objects on the NS
    .EXAMPLE
        Get-NSMonitor -Name ping*

        Retrieves all monitor objects whose name begins with ping
    .NOTES
        Author:             Martin Pugh
        Twitter:            @thesurlyadm1n
        Spiceworks:         Martin9700
        Blog:               www.thesurlyadmin.com
      
        Changelog:
            1.0             Initial Release
    .FUNCTIONALITY
        NetScaler
    .LINK
        http://github.com/RamblingCookieMonster/Citrix.NetScaler
    #>
    [CmdletBinding()]
    Param (
        [string]$Name = "*"
    )

    #Validate NSSession
    ValidateNSSession

    #Retrieve server data
    Invoke-NSCustomQuery -ResourceType lbmonitor | Where MonitorName -like $Name
}