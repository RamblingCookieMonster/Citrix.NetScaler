#Private function to invoke rest method and fall back to HTTP if needed and specified
Function CallInvokeRESTMethod {
    [cmdletbinding()]
    param(
        $IRMParam = $IRMParam,
        $AllowHTTPAuth = $AllowHTTPAuth)
    
    Write-Verbose "Running Invoke-RESTMethod with these parameters:`n$($IRMParam | Format-Table -AutoSize -wrap | Out-String)"

    Try
    {
        Invoke-RestMethod @IRMParam
    }
    
    Catch
    {
        Write-Warning "Error calling Invoke-RESTMethod. Fall back to HTTP = $AllowHTTPAuth. Error details:`n$_"
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
                Write-Error "Fallback to HTTP Failed: $($Error[0])"
            }
        }
    }

}