Function Get-NSService {
    <#
    .SYNOPSIS
        Get service objects for Citrix Netscaler
    .PARAMETER Name
        Filter on the name property, wildcards accepted
    .EXAMPLE
        Get-NSservice

        Retrieves all service objects on the NS
    .EXAMPLE
        Get-NSService -Name ping*

        Retrieves all service objects whose name begins with ping
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
    Invoke-NSCustomQuery -ResourceType service | Where Name -like $Name
}