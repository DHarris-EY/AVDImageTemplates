#################################################################################
# Revision History
#
# Version   Date        Developer                 Description
# 1.0       03/02/2021  Darren Harris\Vikas Gadde Initial Script   
# 1.1       15/02/2021  Darren Harris             Added support for PS1. simply pass the powershell exe path as the cmdline 
#                                                 and add the script to the args.
#################################################################################
#Script description
#This script will take a parameter of a zip file url and a SAS Token and execute a command line from within the zip. 
#################################################################################
<#Param(
     [parameter(mandatory=$true)][string]$URL,
     [parameter(mandatory=$True)][string]$SASToken,
     [parameter(mandatory=$True)][string]$CMDLine,
     [parameter(mandatory=$True)][string]$CMDLineArgs
)#>

#********************************************************************************
#Common script level variables
$EYScriptVersion   = '1.1' #<<<< change this when required.
$EYScriptName      = $MyInvocation.MyCommand.Name
$EYScriptPath      = $MyInvocation.MyCommand.Path
$EYScriptExitCode  = [Int]
$nl                = [Environment]::NewLine
$Cache             =  "C:\ProgramData\EYWVD"
$URL               = "https://acue2spwvdeutx1.file.core.windows.net/fslogixeutx01/EYContent/PersonalV1.1.zip"
$CMDLine           = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
$CMDLineArgs       = "InstallExtras.ps1"
#********************************************************************************

#********************************************************************************
#Script specific variables
#********************************************************************************
[string]$logfile = $env:systemdrive+"\MAINTENANCE\Logs\$EYScriptName.log"
Start-Transcript -Path $LogFile -IncludeInvocationHeader -Append -Force
#********************************************************************************
Write-Host 'Importing required modules...'

#Script Functions
Function EY-Main {
    [CmdletBinding()]
    param ()

    write-EYLog "Script Version: $EYScriptVersion"

    try {
		
        new-item -Path "C:\ProgramData" -ItemType Directory -name EYWVD -Force -ErrorAction Stop

        #$SASToken = ""
        write-EYLog "Attempting to download from URL: $URL"
        $Zip = [System.IO.Path]::GetFileName($URL)
        write-EYLog "Zip name is $Zip"
        
        #Download the file to the cache
        $FnStatus = ""
        $wbresult = GetWebfile ([ref]$FnStatus) -NetChkurl $URL$SASToken -WbDlpath "$cache\$zip"
        write-EYLog "Download of $zip to $cache succeeded: $wbresult"
        
		#Expand the archive
        Expand-Archive -Path "$cache\$Zip" -DestinationPath $Cache -Force
        $extractedfolder = (get-item -Path $cache\$zip).BaseName
        #Execute the Installer
        if (!($cmdline -match "powershell.exe")) {
            write-host "Not calling a powershell script so setting cmdline relative to $cache."
            $cmdline = "$cache\$cmdline"
            
        }
        write-EYLog "Executing $cmdline with arguments $cache\$extractedfolder\$CMDLineArgs"
        $result = Start-Process "$CMDLine" -ArgumentList "$cache\$extractedfolder\$CMDLineArgs"  -PassThru
        $handle = $result.Handle
        $result.WaitForExit()
        write-host "Execution exited with $($result.ExitCode)"

        #Delete the source files post install
        #$extractedfolder = (get-item -Path $cache\$zip).BaseName
        #Remove-Item -Path $cache\$extractedfolder -Recurse -Force
        Remove-Item -Path $cache\$zip -Force
        write-EYLog "Removed $zip"

    }
    catch {
        Write-Error "An error occurred in $($MyInvocation.MyCommand.Name). $nl$_"
        throw $_
    }

}

#################################################################################
#.SYNOPSIS 
# Takes a message and logs it with a EYLOG prefix using write-host
#
#.DESCRIPTION 
# Throws an exception if something went wrong
#
#.OUTPUT
# Returns a result of the execution
#
#.EXAMPLE 
# write-EYLog -EYMessage "Testing Testing"
#################################################################################
function write-EYLog
{
	[CmdletBinding()]
	param ([parameter(Mandatory = $True)]
		[AllowNull()]
		[AllowEmptyString()]
		[string]
		$EYMessage
	)
	try
	{
		$EYPreFix = "EY-LOG:"
		$EYTimeStamp = ""
		if ($TSENV:TaskSequenceID -eq $null)
		{
			$EYTimeStamp = Get-Date
			$EYTimeStamp = ": $EYTimeStamp"
		}
		write-host "$EYPreFix $EYMessage $EYTimeStamp"
	}
	catch
	{
		Write-Error "An error occurred in $($MyInvocation.MyCommand.Name). $nl$_"
		throw $_
	}
	
}
#################################################################################
#.SYNOPSIS 
# Takes a message and logs it with a EYLOGERROR prefix using write-error
#
#.DESCRIPTION 
# Throws an exception if something went wrong
#
#.OUTPUT
# 
#
#.EXAMPLE 
# write-EYLOGERROR -EYMessage "Testing Testing something broke"
#################################################################################
function write-EYLogError
{
	[CmdletBinding()]
	param ([parameter(Mandatory = $True)]
		[AllowNull()]
		[AllowEmptyString()]
		[string]
		$EYMessage
	)
	try
	{
		$EYPreFix = "EY-LOGERROR:"
		$EYTimeStamp = ""
		if ($TSENV:TaskSequenceID -eq $null)
		{
			$EYTimeStamp = Get-Date
			$EYTimeStamp = ": $EYTimeStamp"
		}
		write-error "$EYPreFix $EYMessage $EYTimeStamp"
	}
	catch
	{
		Write-Error "An error occurred in $($MyInvocation.MyCommand.Name). $nl$_"
		throw $_
	}
	
}
#################################################################################
#.SYNOPSIS 
# Takes a message and logs it with a EYLOGWARNING prefix using write-warning
#
#.DESCRIPTION 
# Throws an exception if something went wrong
#
#.OUTPUT
# 
#
#.EXAMPLE 
# write-EYLOGWARNING -EYMessage "Testing Testing something might have gone wrong"
#################################################################################
function write-EYLogWarning
{
	[CmdletBinding()]
	param ([parameter(Mandatory = $True)]
		[AllowNull()]
		[AllowEmptyString()]
		[string]
		$EYMessage
	)
	try
	{
		$EYPreFix = "EY-LOGWARNING:"
		$EYTimeStamp = ""
		if ($TSENV:TaskSequenceID -eq $null)
		{
			$EYTimeStamp = Get-Date
			$EYTimeStamp = ": $EYTimeStamp"
		}
		Write-Warning "$EYPreFix $EYMessage $EYTimeStamp"
	}
	catch
	{
		Write-Error "An error occurred in $($MyInvocation.MyCommand.Name). $nl$_"
		throw $_
	}
	
}
#####################################################################################################################################
################################################## By Ed Kirksey
function GetWebfile {
    Param(
        [Parameter(Mandatory=$true,Position=0)][ref]$FnStatus,
        [Parameter(Mandatory=$true,Position=1)][string]$NetChkurl,
        [Parameter(Mandatory=$true,Position=2)][string]$WbDlpath
    )

    $WebClient = New-Object net.webclient

    $actionStatus = "Retreiving $WbDlpath"
    if (test-path $WbDlpath){
        try{
            remove-item $WbDlpath -Force
            $actionStatus = $actionstatus+"`nprevious copy removed"
        }
        Catch [system.exception]{
            $actionStatus = $actionstatus+"`nFailed to remove previous copy"
            
        }
    }

    Try{
        $ErrorActionPreference = "Stop"
        $WebClient.DownloadFile($NetChkurl, $WbDlpath) 
        $FnStatus.Value = 0
        $actionStatus = $actionstatus+"`nDownload complete"
        return $actionStatus
    }
    Catch [system.exception]{

        $FnStatus.Value = 1603
        $actionStatus = $actionstatus+"`nDownload failed"
        return $actionStatus

    }
}#end function
##################################################
write-EYLog "## $EYScriptName ##################################################################################################"
EY-Main
write-EYLog "## $EYScriptName End ################################################################################################"
Stop-Transcript
