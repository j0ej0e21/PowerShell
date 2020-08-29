function Connect-MEMCM
{
    # Site configuration
    $SiteCode = "AMG" # Site code 
    $ProviderMachineName = "scmprdw1000.amerigas.com" # SMS Provider machine name

    # Customizations
    $initParams = @{}
    #$initParams.Add("Verbose", $true) # Uncomment this line to enable verbose logging
    #$initParams.Add("ErrorAction", "Stop") # Uncomment this line to stop the script on any errors

    # Do not change anything below this line

    # Import the ConfigurationManager.psd1 module 
    if((Get-Module ConfigurationManager) -eq $null) {
        Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" @initParams 
    }

    # Connect to the site's drive if it is not already present
    if((Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) {
        New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ProviderMachineName @initParams
    }

    # Set the current location to be the site code.
    Set-Location "$($SiteCode):\" @initParams

    $initParams = @{}
    $initParams.Add("Verbose", $true) # Uncomment this line to enable verbose logging
    $initParams.Add("ErrorAction", "Stop") # Uncomment this line to stop the script on any errors

    # Do not change anything below this line

    # Import the ConfigurationManager.psd1 module 
    Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1"
}

function Get-CMModule 
{ 
    [CmdletBinding()] 
    param() 
    Try 
    { 
        Write-Verbose "Attempting to import SCCM Module" -Verbose
        Import-Module (Join-Path $(Split-Path $ENV:SMS_ADMIN_UI_PATH) ConfigurationManager.psd1) -Verbose:$false 
        Write-Verbose "Successfully imported the SCCM Module" -Verbose
    } 
    Catch 
    { 
        Throw "Failure to import SCCM Cmdlets." 
    } 
}

function Pull-CMDevices
{
    param([string[]]$devices)

    Connect-MEMCM

    $machines = @()

    foreach($device in $devices)
    {
       $machine =  Get-CMDevice -Name $device
       $machines += $machine
    }
    
    return $machines
}

function Get-MachinesFromUsernames
{
	
	param (
		[string]$inputfile,
		[string]$outputfile
    )
    	
	Connect-MEMCM
	
	$devices = @()
    $names = get-content $inputfile
    Write-Verbose -Message "There are $($names.count) usernames in the input file..." -Verbose
    $notfound = @()
    $notfoundfile = $outputfile.Substring(0, $outputfile.lastIndexOf('\'))
    $notfoundfile = "$notfoundfile" + "\notfound.csv"

	foreach ($name in $names)
	{
        try
        {
            $machines = get-cmdevice | where { $_.username -eq $name } -ErrorAction Stop
        }
        catch
        {

        }
        $devices += $machines
        if(!$machines)
        {
            $notfound += $name
        }
	}
	
    $devices | Select Name, UserName | Export-Csv -Path $outputfile -NoTypeInformation
    $notfound | Out-File -FilePath $notfoundfile 
    Write-Verbose -Message "$($devices.Count) devices were found inside of SCCM that match the usernames provided..." -Verbose
    Write-Verbose -Message "$($notfound.Count) usernames did not match a machine...These have been saved at $($notfoundfile)" -Verbose
}

Export-ModuleMember -Function *
Export-ModuleMember -Variable *
Export-ModuleMember -Cmdlet *
