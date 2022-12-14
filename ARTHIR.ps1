<#
  ___  ______ _____ _   _ ___________
 / _ \ | ___ \_   _| | | |_   _| ___ \
/ /_\ \| |_/ / | | | |_| | | | | |_/ /
|  _  ||    /  | | |  _  | | | |    /
| | | || |\ \  | | | | | |_| |_| |\ \
\_| |_/\_| \_| \_/ \_| |_/\___/\_| \_|

.VERSION
Version 1.0 - Mar 2019
This version was forked and updated by Malware Archaeology to run more than just powerShell scripts
  https://github.com/MalwareArchaeology/ARTHIR
  http://www.ARTHIR.com
  
Shout out to Olaf Hartong for his assistance in updates to this script.

.SYNOPSIS
ARTHIR is a Powershell based incident response framework for Windows 
environments.  This is a forked and improved version of the KANSA project.

.DESCRIPTION
ARTHIR is a modular, PowerShell based incident response framework for
Windows environments that have Windows Remote Management enabled.

ARTHIR looks for a modules.conf file in the .\Modules directory. If one
is found, it controls which modules execute and in what order. If no 
modules.conf is found, all modules will be executed in the order that 
ls reads them.

After parsing modules.conf or the -ModulesPath parameter argument, 
ARTHIR will execute each module on each target (remote host) and 
write the output to a folder named for each module in a time stamped
output path. Each target will have its data written to separate files.

For example, the Get-PS_Version_Logging_Details.ps1 module data will be written
to: 
  * Output_timestamp\Get-PS_Version_Logging_Details\Hostname\hostname-Get-PS_Version_Logging_Details.txt.

All modules should create and then return reports. 

ARTHIR.ps1 like Kansa was written to avoid the need for CredSSP, therefore 
"second-hops" should be avoided. For more details on this see:

  * http://trustedsignal.blogspot.com/2014/04/kansa-modular-live-response-tool-for.html

The script assumes you will have administrator level privileges on
target hosts, though such privileges may not be required by all 
modules.

If you run this script without the -TargetList argument, Remote Server
Administration Tools (RSAT), is required to query Active Directory. 
RSAT is available from Microsoft's Download Center for Windows 7 and 8. 
You can search for RSAT at:

  * http://www.microsoft.com/en-us/download/default.aspx

.PARAMETER ModulePath
An optional parameter, default value is .\Modules\, that specifies the
path to the collector modules or a specific module. Spaces in the path 
are not supported, however, ModulePath may point directly to a specific 
module and if that module takes a parameter, you should have a space 
between the path to the script and its first argument, put the whole 
thing in quotes. See example.

.PARAMETER TargetList
An optional parameter, the name of a file containing a list of servers 
to collect data from. If these hosts are outside the current forest, 
fully qualified domain names are required. In general, it is advised to
use FQDNs.

PARAMETER Target
An optional parameter, the name of a single system to collect data from.

.PARAMETER TargetCount
An optional parameter that specifies the maximum number of targets.

In the absence of the TargetList and / or Target arguments, ARTHIR will 
use Remote System Administration Tools (a separate installed package) 
to query Active Directory and will build a list of hosts to target 
automatically.

.PARAMETER Credential
An optional credential that the script will use for execution. Use the
$Credential = Get-Credential convention to populate a suitable variable.

.PARAMETER Pushbin
An optional flag that causes ARTHIR to push required binaries to the 
ADMIN$ shares of targets. Modules that require third-party binaries, 
must include the "BINDEP <binary>" directive.

For example, the Get-LOG-MD_Autoruns.ps1 collector has a dependency on
IMF Security LOG-MD. The Get-LOG-MD-Autoruns.ps1 collector 
contains a special line called a "directive" that instructs ARTHIR.ps1
to copy the LOG-MD.exe binary to remote systems when called with the
-Pushbin flag. ARTHIR will push the binary, assuming the user placed
any required binaries into the \Modules\bin\ path.  

Only LOG-MD Free Edition is distributed with ARTHIR, all other tools/utilities/binaries 
the user must download and place into the \Modules\bin\ path and adjust the Bindep
directive to reference the proper binary in the appropriate module.

Directives should be placed in module's .SYNOPSIS sections under .NOTES
    * Directives must appear on a line by themselves
    * Directives must start the line 
    # ARTHIR - Directives must be in all CAPITAL letters

For example, the directive for Get-LOG-MD-Autoruns.ps1 as of this writing is
  * BINDEP .\Modules\bin\LOG-MD.exe

If your required binaries are already present on each target and in the 
path where the modules expect them to be, you can omit the -Pushbin 
flag and save the step of copying binaries.

.PARAMETER Rmbin
An optional switch for removing binaries that may have been pushed to
remote hosts via -Pushbin either on this run, or during a previous run.

.PARAMETER Ascii
An optional switch that tells ARTHIR you want all text output (i.e. txt,
csv and tsv) and errors written as Ascii. Unicode is the default.

.PARAMETER UpdatePath
An optional switch that adds Analysis script paths to the user's path 
and then exits. ARTHIR will automatically add Analysis script paths to
the user's path when run normally, this switch is for convenience when
coming back to the data for analysis.

.PARAMETER ListModules
An optional switch that lists the available modules. Useful for
constructing a modules.conf file. ARTHIR exits after listing.
You'll likely want to sort the according to the order of volatility.

.PARAMETER ListAnalysis
An optional switch that lists the available analysis scripts. Useful 
for constructing an analysis.conf file. ARTHIR exits after listing. If 
you use this switch to build an analysis.conf file, you'll likely want 
to edit the list so you're only running the analysis scripts you want 
to run.

.PARAMETER Analysis
An optional switch that causes ARTHIR to run automated analysis based on
the contents of the Analysis\Analysis.conf file.

.PARAMETER Transcribe
An optional flag that causes Start-Transcript to run at the start
of the script, writing to $OutputPath\yyyyMMddhhmmss.log

.PARAMETER Quiet
An optional flag that overrides ARTHIR's default of running with -Verbose.

.PARAMETER UseSSL
An optional flag for use in environments that have authentication
certificates deployed. If this flag is used and certificates are
deployed, connections will be made over HTTPS and will be encrypted.
Without this flag traffic passes in the clear. Note authentication is
done via Kerberos regardless of whether or not SSL is used. Alternate
authentication methods are available via the -Authentication parameter
argument.

.PARAMETER Port
An optional parameter if WinRM is listening on a non-standard port.

.PARAMETER Authentication
An optional parameter specifying what authentication method should be 
used. The default is Kerberos, but that won't work for authenticating
against local administrator accounts or for scenarios with non-domain
joined systems. 

Valid options: Basic, CredSSP, Default, Digest, Kerberos, Negotiate, 
NegotiateWithImplicitCredential.

Whereever possible, you should use Kerberos, some of these options are
considered dangerous, so be careful and read up on the different
methods before using an alternate.

.PARAMETER JSONDepth
An optional parameter specifying how many levels of contained objects
are included in the JSON representation. Default is 10.

.PARAMETER Rmdownload
An optional switch for removing files that have been downloaded by the 
module. The files were most likely temporary (output) files as a result 
of the binary that ran.

.INPUTS
None, you cannot pipe objects to this cmdlet

.OUTPUTS
The reports generated by your module and any errors and transcript files which are .TXT.

.NOTES
In the absence of a configuration file, specifying which modules to run, 
this script will run each module across all hosts.

Each module should return objects.

Because modules should only COLLECT data from remote hosts, their 
filenames must begin with "Get-". Examples:
  * Get-PrefetchListing.ps1
  * Get-Netstat.ps1

Any module not beginning with "Get-" will be ignored.

Note: this read-only aspect is unenforced, therefore, ARTHIR can be used 
to make changes to remote hosts. As a result, it can be used to 
facilitate remediation or configuration changes.

The script can take a list of targets, read from a text file, via the
-TargetList <file> argument. You may also supply the -TargetCount 
argument to limit how many hosts will be targeted. To target a single
host, use the -Target <hostname> argument.

In the absence of the -TargetList or -Target arguments, ARTHIR.ps1 will
query Acitve Directory for a complete list of hosts and will attempt to
target all of them.  Warning, this could take a while... Test it first.

.EXAMPLE
 * ARTHIR.ps1

 In the above example the user has specified no arguments, which will
cause ARTHIR to run modules per the .\Modules\Modules.conf file against
a list of hosts that it is able to query from Active Directory. Errors
and all output will be written to a timestamped output directory. If
.\Modules\Modules.conf is not found, all ps1 scripts starting with Get-
under the .\Modules\ directory (recursively) will be run.
  * Not recommended unless you test and know how long and what you want to run

.EXAMPLE
 * ARTHIR.ps1 -TargetList hosts.txt -Credential $Credential -Transcribe

 In this example the user has specified a list of hosts to target, a 
user credential under which to execute. The -Transcribe flag is also
supplied, causing all script output to be written to a transcript. By
default, the script will also output verbose runstate information.

.EXAMPLE
 * ARTHIR.ps1 -ModulePath ".\Modules\Info\Get-PS_Version_Logging_Details.ps1" -Target Pluto

In this example -ModulePath refers to a specific module that is run 
against a single target.

.EXAMPLE
 * ARTHIR.ps1 -TargetList hostlist -Analysis
Runs collection according to the configuration in Modules\Modules.conf.
Following collection, runs analysis scripts per Analysis\Analysis.conf.

.EXAMPLE
 * ARTHIR.ps1 -ListModules
Returns a list of all the modules found under the default modules path.

.EXAMPLE
 * ARTHIR.ps1 -ListAnalysis
Returns a list of all analysis scripts found under the Analysis path.

#>

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$False,Position=0)]
        [String]$ModulePath="Modules\",
    [Parameter(Mandatory=$False,Position=1)]
        [String]$TargetList=$Null,
    [Parameter(Mandatory=$False,Position=2)]
        [String]$Target=$Null,
    [Parameter(Mandatory=$False,Position=3)]
        [int]$TargetCount=0,
    [Parameter(Mandatory=$False,Position=4)]
        [System.Management.Automation.PSCredential]$Credential=$Null,
    [Parameter(Mandatory=$False,Position=5)]
    [ValidateSet("CSV","JSON","TSV","XML")]
        [String]$OutputFormat="CSV",
    [Parameter(Mandatory=$False,Position=6)]
        [Switch]$Pushbin,
    [Parameter(Mandatory=$False,Position=7)]
        [Switch]$Rmbin,
    [Parameter(Mandatory=$False,Position=8)]
        [Int]$ThrottleLimit=0,
    [Parameter(Mandatory=$False,Position=9)]
    [ValidateSet("Ascii","BigEndianUnicode","Byte","Default","Oem","String","Unicode","Unknown","UTF32","UTF7","UTF8")]
        [String]$Encoding="Unicode",
    [Parameter(Mandatory=$False,Position=10)]
        [Switch]$UpdatePath,
    [Parameter(Mandatory=$False,Position=11)]
        [Switch]$ListModules,
    [Parameter(Mandatory=$False,Position=12)]
        [Switch]$ListAnalysis,
    [Parameter(Mandatory=$False,Position=13)]
        [Switch]$Analysis,
    [Parameter(Mandatory=$False,Position=14)]
        [Switch]$Transcribe,
    [Parameter(Mandatory=$False,Position=15)]
        [Switch]$Quiet=$False,
    [Parameter(Mandatory=$False,Position=16)]
        [Switch]$UseSSL,
    [Parameter(Mandatory=$False,Position=17)]
        [ValidateRange(0,65535)]
        [uint16]$Port=5985,
    [Parameter(Mandatory=$False,Position=18)]
        [ValidateSet("Basic","CredSSP","Default","Digest","Kerberos","Negotiate","NegotiateWithImplicitCredential")]
        [String]$Authentication="Kerberos",
    [Parameter(Mandatory=$false,Position=19)]
        [int32]$JSONDepth="10",
    [Parameter(Mandatory=$false,Position=20)]
        [Switch]$Rmdownload,
    [Parameter(Mandatory=$false,Position=21)]
        [Switch]$Timeout,
    [Parameter(Mandatory=$false,Position=22)]
        [String]$Modconf=".\Modules\Modules.conf",
    [Parameter(Mandatory=$false,Position=23)]
        [String]$OutputPath = $(Get-Location | Select-Object -ExpandProperty Path) + "\Output_$([String] (Get-Date -Format yyyyMMddHHmmss))\"
)

# ARTHIR - Opening with a Try so the Finally block at the bottom will always call
# ARTHIR - the Exit-Script function and clean up things as needed.

Try {

# ARTHIR - Long paths prevent data from being written, this is used to test their length
# ARTHIR - Per http://msdn.microsoft.com/en-us/library/aa365247.aspx#maxpath, maximum
# ARTHIR - path length should be 260 characters. We set it to 241 here to account for
# ARTHIR - max computername length of 15 characters, it's part of the path, plus a 
# ARTHIR - hyphen separator and a dot-three extension.
# ARTHIR - extension -- 260 - 19 = 241.

Set-Variable -Name MAXPATH -Value 241 -Option Constant

# ARTHIR - Since ARTHIR provides so much useful information through Write-Vebose, we
# ARTHIR - want it to run with that flag enabled by default. This behavior can be
# ARTHIR - overridden by passing the -Quiet flag. This is scoped only to this context,
# ARTHIR - so we don't need to reset it when we're done.

if(!$Quiet) {
    $VerbosePreference = "Continue"
	}

function FuncTemplate {
<#
.SYNOPSIS
ARTHIR - Default function template, copy when making new function
#>
Param(
    [Parameter(Mandatory=$False,Position=0)]
        [String]$ParamTemplate=$Null
)
    Write-Debug "Entering $($MyInvocation.MyCommand)"
    $Error.Clear()
    # ARTHIR - Non-terminating errors can be checked via
    if ($Error) {
        # ARTHIR - Write the $Error to the $Errorlog
        $Error | Add-Content -Encoding $Encoding $ErrorLog
        $Error.Clear()
    }

    Try { 
        <# ARTHIR - 
        Try/Catch blocks are for terminating errors. See some of the
        functions below for examples of how non-terminating errors can 
        be caught and handled. 
        #>
    } Catch [Exception] {
        $Error | Add-Content -Encoding $Encoding $ErrorLog
        $Error.Clear()
    }
    Write-Debug "Exiting $($MyInvocation.MyCommand)"    
}
<# ARTHIR - End FuncTemplate #>

function Exit-Script {
<#
.SYNOPSIS
ARTHIR - Exit the script somewhat gracefully, closing any open transcript.
#>
    Set-Location $StartingPath
    if ($Transcribe) {
        [void] (Stop-Transcript)
    }

    if ($Error) {
        "Exit-Script function was passed an error, this may be a duplicate that wasn't previously cleared, or ARTHIR.ps1 has crashed." | Add-Content -Encoding $Encoding $ErrorLog
        $Error | Add-Content -Encoding $Encoding $ErrorLog
        $Error.Clear()
    }

    if ($Error) {
        Write-Output "Script completed with warnings or errors. See ${ErrorLog} for details."
    }

    if (!(Get-ChildItem -Force $OutputPath)) {
        # ARTHIR - $OutputPath is empty, delete it
# ARTHIR - "Output path was created, but ARTHIR finished with no hits, no runs and no errors. Deleting the folder."
        [void] (Remove-Item $OutputPath -Force)
    }

    Exit
}

function Get-Modules {

<#
.SYNOPSIS
Looks for modules.conf in the $Modulepath, default is Modules. If found,
returns an ordered hashtable of script files and their arguments, if any. 
If no modules.conf is found, returns an ordered hashtable of all modules
found in $Modulepath, but no arguments will be present so scripts will
run with default params. A module is a .ps1 script starting with Get-.
#>

Param(
    [Parameter(Mandatory=$True,Position=0)]
        [String]$ModulePath
)
    Write-Debug "Entering $($MyInvocation.MyCommand)"
    $Error.Clear()
    # ARTHIR - ToDo: There should probably be some error handling in this function.

    Write-Debug "`$ModulePath is ${ModulePath}."

    # ARTHIR - User may have passed a full path to a specific module, possibly with an argument
    $ModuleScript = ($ModulePath -split " ")[0]
    $ModuleArgs   = @($ModulePath -split [regex]::escape($ModuleScript))[1].Trim()

    $Modules = $FoundModules = @()
    # ARTHIR - Need to maintain the order for "order of volatility"
    $ModuleHash = New-Object System.Collections.Specialized.OrderedDictionary

    if (!(ls $ModuleScript | Select-Object -ExpandProperty PSIsContainer)) {
        # ARTHIR - User may have provided full path to a .ps1 module, which is how you run a single module explicitly
        $ModuleHash.Add((ls $ModuleScript), $ModuleArgs)

        if (Test-Path($ModuleScript)) {
            $Module = ls $ModuleScript | Select-Object -ExpandProperty BaseName
			Write-Verbose "Running module: `n$Module $ModuleArgs"
            Return $ModuleHash
        }
    }
    if (Test-Path($Modconf)) {
        Write-Verbose "Found ${Modconf}."
        # ARTHIR - ignore blank and commented lines, trim misc. white space
        Get-Content $Modconf | Foreach-Object { $_.Trim() } | Where-Object { $_ -gt 0 -and (!($_.StartsWith("#"))) } | Foreach-Object { $Module = $_
            # ARTHIR - verify listed modules exist
            $ModuleScript = ($Module -split " ")[0]
            $ModuleArgs   = ($Module -split [regex]::escape($ModuleScript))[1].Trim()
            $Modpath = $ModulePath + "\" + $ModuleScript
            if (!(Test-Path($Modpath))) {
                "WARNING: Could not find module specified in ${Modconf}: $ModuleScript. Skipping." | Add-Content -Encoding $Encoding $ErrorLog
            } else {
                # ARTHIR - module found add it and its arguments to the $ModuleHash
                $ModuleHash.Add((ls $ModPath), $Moduleargs)
                # ARTHIR - $FoundModules += ls $ModPath # ARTHIR - deprecated code, remove after testing
            }
        }
        # ARTHIR - $Modules = $FoundModules # ARTHIR - deprecated, remove after testing
    } else {
        # ARTHIR - we had no modules.conf
        ls -r "${ModulePath}\Get-*.ps1" | Foreach-Object { $Module = $_
            $ModuleHash.Add($Module, $null)
        }
    }
    Write-Verbose "Running modules:`n$(($ModuleHash.Keys | Select-Object -ExpandProperty BaseName) -join "`n")"
    $ModuleHash
    Write-Debug "Exiting $($MyInvocation.MyCommand)"
}

function Load-AD {
    # ARTHIR - no targets provided so we'll query AD to build it, need to load the AD module
    Write-Debug "Entering $($MyInvocation.MyCommand)"
    if (Get-Module -ListAvailable | Where-Object { $_.Name -match "ActiveDirectory" }) {
        $Error.Clear()
        Import-Module ActiveDirectory
        if ($Error) {
            "ERROR: Could not load the required Active Directory module. Please install the Remote Server Administration Tool for AD. Quitting." | Add-Content -Encoding $Encoding $ErrorLog
            $Error.Clear()
            Exit
        }
    } else {
        "ERROR: Could not load the required Active Directory module. Please install the Remote Server Administration Tool for AD. Quitting." | Add-Content -Encoding $Encoding $ErrorLog
        $Error.Clear()
        Exit
    }
    Write-Debug "Exiting $($MyInvocation.MyCommand)"
}

function Get-Forest {
    # ARTHIR - what forest are we in?
    Write-Debug "Entering $($MyInvocation.MyCommand)"
    $Error.Clear()
    $Forest = (Get-ADForest).Name

    if ($Forest) {
        Write-Verbose "Forest is ${forest}."
        $Forest
    } elseif ($Error) {
        # ARTHIR - Write the $Error to the $Errorlog
        $Error | Add-Content -Encoding $Encoding $ErrorLog
        "ERROR: Get-Forest could not find current forest. Quitting." | Add-Content -Encoding $Encoding $ErrorLog
        $Error.Clear()
        Exit
    }
}

function Get-Targets {
Param(
    [Parameter(Mandatory=$False,Position=0)]
        [String]$TargetList=$Null,
    [Parameter(Mandatory=$False,Position=1)]
        [int]$TargetCount=0
)
    Write-Debug "Entering $($MyInvocation.MyCommand)"
    $Error.Clear()
    $Targets = $False
    if ($TargetList) {
        # ARTHIR - user provided a list of targets
        if ($TargetCount -eq 0) {
            $Targets = Get-Content $TargetList | Foreach-Object { $_.Trim() } | Where-Object { $_.Length -gt 0 }
        } else {
            $Targets = Get-Content $TargetList | Foreach-Object { $_.Trim() } | Where-Object { $_.Length -gt 0 } | Select-Object -First $TargetCount
        }
    } else {
        # ARTHIR - no target list provided, we'll query AD for it
        Write-Verbose "`$TargetCount is ${TargetCount}."
        if ($TargetCount -eq 0 -or $TargetCount -eq $Null) {
            $Targets = Get-ADComputer -Filter * | Select-Object -ExpandProperty Name 
        } else {
            $Targets = Get-ADComputer -Filter * -ResultSetSize $TargetCount | Select-Object -ExpandProperty Name
        }
        # ARTHIR - Iterate through targets, cleaning up AD Replication errors
        # ARTHIR - In some AD environments, when there are duplicate object names, AD will add the objectGUID to the Name
        # ARTHIR - displayed in the format of "hostname\0ACNF:ObjectGUID".  If you expand the property Name, you get 2 lines
        # ARTHIR - returned, the hostname, and then CNF:ObjectGUID. This code will look for hosts with more than one line and return
        # ARTHIR - the first line which is assumed to be the host name.
        foreach ($item in $Targets) {
            $numlines = $item | Measure-Object -Line
            if ($numlines.Lines -gt 1) {
                $lines = $item.Split("`n")
                $i = [array]::IndexOf($targets, $item)
                $targets[$i] = $lines[0]
            }
        }
        $TargetList = "hosts.txt"
        Set-Content -Path $TargetList -Value $Targets -Encoding $Encoding
    }

    if ($Targets) {
        Write-Verbose "`$Targets are ${Targets}."
        return $Targets
    } else {
        Write-Verbose "Get-Targets function found no targets. Checking for errors."
    }
    
    if ($Error) { # ARTHIR - if we make it here, something went wrong
        $Error | Add-Content -Encoding $Encoding $ErrorLog
        "ERROR: Get-Targets function could not get a list of targets. Quitting."
        $Error.Clear()
        Exit
    }
    Write-Debug "Exiting $($MyInvocation.MyCommand)"
}

function Get-LegalFileName {
<#
.SYNOPSIS
Returns argument with illegal filename characters removed.
#>
Param(
    [Parameter(Mandatory=$True,Position=0)]
        [Array]$Argument
)
    Write-Debug "Entering ($MyInvocation.MyCommand)"
    $Argument = $Arguments -join ""
    $Argument -replace [regex]::Escape("\") -replace [regex]::Escape("/") -replace [regex]::Escape(":") `
        -replace [regex]::Escape("*") -replace [regex]::Escape("?") -replace "`"" -replace [regex]::Escape("<") `
        -replace [regex]::Escape(">") -replace [regex]::Escape("|") -replace " "
}

function Get-Directives {
<#
.SYNOPSIS
Returns a hashtable of directives found in the script
Directives are used for two things:
1) The BINDEP directive tells ARTHIR that a module depends on some 
binary and what the name of the binary is. If ARTHIR is called with 
-PushBin, the script will look in Modules\bin\ for the binary and 
attempt to copy it to targets. Specify multiple BINDEPs by
separating each path with a semi-colon (;).

2) The DATADIR directive tells ARTHIR what the output path is for
the given module's data so that if it is called with the -Analysis
flag, the analysis scripts can find the data.
TK Some collector output paths are dynamically generated based on
arguments, so this breaks for analysis. Solve.
#>
Param(
    [Parameter(Mandatory=$True,Position=0)]
        [String]$Module,
    [Parameter(Mandatory=$False,Position=1)]
        [Switch]$AnalysisPath
)
    Write-Debug "Entering $($MyInvocation.MyCommand)"
    $Error.Clear()
    if ($AnalysisPath) {
        $Module = ".\Analysis\" + $Module
    }

    if (Test-Path($Module)) {
        
        $DirectiveHash = @{}

        Get-Content $Module | Select-String -CaseSensitive -Pattern "BINDEP|DATADIR|DOWNLOAD" | Foreach-Object { $Directive = $_
            if ( $Directive -match "(^BINDEP|^# ARTHIR - BINDEP) (.*)" ) {
                $DirectiveHash.Add("BINDEP", $($matches[2]))
            }
            if ( $Directive -match "(^DATADIR|^# ARTHIR - DATADIR) (.*)" ) {
                $DirectiveHash.Add("DATADIR", $($matches[2])) 
            }
			if ( $Directive -match "(^DOWNLOAD|^# ARTHIR - DOWNLOAD) (.*)" ) {
                $DirectiveHash.Add("DOWNLOAD", $($matches[2])) 
            }
        }
        $DirectiveHash
    } else {
        "WARNING: Get-Directives was passed invalid module $Module." | Add-Content -Encoding $Encoding $ErrorLog
    }
}


function Get-TargetData {
<#
.SYNOPSIS
Runs each module against each target. Writes out the returned data to host where ARTHIR is run from.
#>
Param(
    [Parameter(Mandatory=$True,Position=0)]
        [Array]$Targets,
    [Parameter(Mandatory=$True,Position=1)]
        [System.Collections.Specialized.OrderedDictionary]$Modules,
    [Parameter(Mandatory=$False,Position=2)]
        [System.Management.Automation.PSCredential]$Credential=$False,
    [Parameter(Mandatory=$False,Position=3)]
        [Int]$ThrottleLimit
)
    Write-Debug "Entering $($MyInvocation.MyCommand)"
    $Error.Clear()

    # ARTHIR - Create our sessions with targets
    if ($Credential) {
        if ($UseSSL) {
            $PSSessions = New-PSSession -ComputerName $Targets -Port $Port -UseSSL -Authentication $Authentication -SessionOption (New-PSSessionOption -NoMachineProfile) -Credential $Credential
        } else {
            $PSSessions = New-PSSession -ComputerName $Targets -Port $Port -Authentication $Authentication -SessionOption (New-PSSessionOption -NoMachineProfile) -Credential $Credential
        }
    } else {
        if ($UseSSL) {
            $PSSessions = New-PSSession -ComputerName $Targets -Port $Port -UseSSL -Authentication $Authentication -SessionOption (New-PSSessionOption -NoMachineProfile)
        } else {
            $PSSessions = New-PSSession -ComputerName $Targets -Port $Port -Authentication $Authentication -SessionOption (New-PSSessionOption -NoMachineProfile)
        }
    }

    # ARTHIR - Check for and log errors
    if ($Error) {
        $Error | Add-Content -Encoding $Encoding $ErrorLog
        $Error.Clear()
    }
    $Modules.Keys | Foreach-Object { $Module = $_
        $ModuleName  = $Module | Select-Object -ExpandProperty BaseName
        $Arguments   = @()
        $Arguments   += $($Modules.Get_Item($Module)) -split ","
        if ($Arguments) {
            $ArgFileName = Get-LegalFileName $Arguments
        } else { $ArgFileName = "" }
        # ARTHIR - Get our directives both old and new style
        $DirectivesHash  = @{}
        $DirectivesHash = Get-Directives $Module

        if ($Pushbin) {
            $bindeps = [string]$DirectivesHash.Get_Item("BINDEP") -split ';'
            foreach($bindep in $bindeps) {
                if ($bindep) {
                
                    # ARTHIR - Send-File only supports a single destination at a time, so we have to loop this.
                    foreach ($PSSession in $PSSessions)
                    {
                        $RemoteWindir = Invoke-Command -Session $PSSession -ScriptBlock { Get-ChildItem -Force env: | Where-Object { $_.Name -match "windir" } | Select-Object -ExpandProperty value }
                        $null = Send-File -Path (ls $bindep).FullName -Destination $RemoteWindir -Session $PSSession
                    }
                }
            }
        }

        # ARTHIR - run the module on the targets            
        if ($Arguments) {
            Write-Debug "Invoke-Command -Session $PSSessions -FilePath $Module -ArgumentList `"$Arguments`" -AsJob -ThrottleLimit $ThrottleLimit"
            $Job = Invoke-Command -Session $PSSessions -FilePath $Module -ArgumentList $Arguments -AsJob -ThrottleLimit $ThrottleLimit
            Write-Verbose "Waiting for $ModuleName $Arguments to complete."
        } else {
            Write-Debug "Invoke-Command -Session $PSSessions -FilePath $Module -AsJob -ThrottleLimit $ThrottleLimit"
            $Job = Invoke-Command -Session $PSSessions -FilePath $Module -AsJob -ThrottleLimit $ThrottleLimit                
            Write-Verbose "Waiting for $ModuleName to complete."
        }
        # ARTHIR - Wait-Job does return data to stdout, add $suppress = to start of next line, if needed
        if ($Timeout) {
            Wait-Job $Job -Timeout $Timeout
        } else {
            Wait-Job $Job
        }
            
        # ARTHIR - set up our output location
        $GetlessMod = $($ModuleName -replace "Get-") 
        # ARTHIR - Long paths prevent output from being written, so we truncate $ArgFileName to accommodate
        # ARTHIR - We're estimating the output path because at this point, we don't know what the hostname
        # ARTHIR - is and it is part of the path. Hostnames are 15 characters max, so we assume worst case
        $EstOutPathLength = $OutputPath.Length + ($GetlessMod.Length * 2) + ($ArgFileName.Length * 2)
        if ($EstOutPathLength -gt $MAXPATH) { 
            # ARTHIR - Get the path length without the arguments, then we can determine how long $ArgFileName can be
            $PathDiff = [int] $EstOutPathLength - ($OutputPath.Length + ($GetlessMod.Length * 2) -gt 0)
            $MaxArgLength = $PathDiff - $MAXPATH
            if ($MaxArgLength -gt 0 -and $MaxArgLength -lt $ArgFileName.Length) {
                $OrigArgFileName = $ArgFileName
                $ArgFileName = $ArgFileName.Substring(0, $MaxArgLength)
                "WARNING: ${GetlessMod}'s output path contains the arguments that were passed to it. Those arguments were truncated from $OrigArgFileName to $ArgFileName to accommodate Window's MAXPATH limit of 260 characters." | Add-Content -Encoding $Encoding $ErrorLog
            }
        }
               
#        if (!(Test-Path $OutputPath$GetlessMod$ArgFileName)) {
#            [void] (New-Item -Path $OutputPath -name ($GetlessMod + $ArgFileName) -ItemType Directory)
#        }
        $Job.ChildJobs | Foreach-Object { $ChildJob = $_
            $Recpt = Receive-Job $ChildJob
            
            # ARTHIR - Log errors from child jobs, including module and host that failed.
            if($Error) {
                $ModuleName + " reports error on " + $ChildJob.Location + ": `"" + $Error + "`"" | Add-Content -Encoding $Encoding $ErrorLog
                $Error.Clear()
# ARTHIR - Depricated for direct output to a file that is then returned
#            }

            # ARTHIR - Now that we know our hostname, let's double check our path length, if it's too long, we'll write an error
            # ARTHIR - Max path is 260 characters, if we're over 256, we can't accomodate an extension
#            $Outfile = $OutputPath + $GetlessMod + $ArgFileName + "\" + $ChildJob.Location + "-" + $GetlessMod + $ArgFileName
#            if ($Outfile.length -gt 256) {
#                "ERROR: ${GetlessMod}'s output path length exceeds 260 character limit. Can't write the output to disk for $($ChildJob.Location)." | Add-Content -Encoding $Encoding $ErrorLog
#                Return
#            }

            # ARTHIR - save the data of the raw output that is no longer used  This section is not useful !!!!!!!!!!!!!!!!!!!!!!!!!!!
#            switch -Wildcard ($OutputFormat) {
#                "*csv" {
#                    $Outfile = $Outfile + ".csv"
#                    $Recpt | Export-Csv -NoTypeInformation -Encoding $Encoding $Outfile
#                }
#                "*json" {
#                    $Outfile = $Outfile + ".json"
#                    $Recpt | ConvertTo-Json -Depth $JSONDepth | Set-Content -Encoding $Encoding $Outfile
#                }
#                "*tsv" {
#                    $Outfile = $Outfile + ".tsv"
#                    # ARTHIR - LogParser can't handle quoted tab separated values, so we'll strip the quotes.
#                    $Recpt | ConvertTo-Csv -NoTypeInformation -Delimiter "`t" | ForEach-Object { $_ -replace "`"" } | Set-Content -Encoding $Encoding $Outfile
#                }
#                "*xml" {
#                    $Outfile = $Outfile + ".xml"
#                    $Recpt | Export-Clixml $Outfile -Encoding $Encoding
#                }
#                <# ARTHIR - Following output formats are no longer supported in ARTHIR
#                "*bin" {
#                    $Outfile = $Outfile + ".bin"
#                    $Recpt | Set-Content -Encoding Byte $Outfile
#                }
#                "*zip" {
#                    # ARTHIR - Compression should be done in the collector
#                    # ARTHIR - Default collector template has a function
#                    # ARTHIR - for compressing data as an example
#                    $Outfile = $Outfile + ".zip"
#                    $Recpt | Set-Content -Encoding Byte $Outfile
#                }
#                #>
#                default {
#                    $Outfile = $Outfile + ".csv"
#                    $Recpt | Export-Csv -NoTypeInformation -Encoding $Encoding $Outfile
#                }
            }
        }

        # ARTHIR - Output.
        Remove-Job $Job

        if ($rmbin) {
            if ($bindeps) {
                foreach ($bindep in $bindeps) {
                    $RemoteBinDep = "$RemoteWinDir\$(split-path -path $bindep -leaf)"
                    Invoke-Command -Session $PSSession -ScriptBlock { Remove-Item -force -path $using:RemoteBinDep}
                }
            }
        }

		$files = [string]$DirectivesHash.Get_Item("DOWNLOAD") -split ';'
		foreach($file in $files) {
			if ($file) {
				# ARTHIR - Send-File only supports a single destination at a time, so we have to loop this.
				foreach ($PSSession in $PSSessions)
				{
					$dir = Split-Path -Path $file
					$dirLength = $dir.length
					$RemoteFiles = Invoke-Command -Session $PSSession -ScriptBlock {Get-ChildItem $using:file -rec | Where-Object { ! $_.PSIsContainer }}
					foreach ($RemoteFile in $RemoteFiles) 
					{
						$FilePath = $OutputPath+$ModuleName+"\"+$PSSession.ComputerName+"\"+([string]$RemoteFile.FullName).Substring($dirLength+1)
						Write-Host $FilePath
						$destdir = (Split-Path -Path $FilePath)
						if (!(Test-Path (Split-Path -Path $FilePath))) {$null = New-Item -ItemType Directory -Force -Path $destdir}
						if ($PSVersionTable.PSVersion.major -lt 5) {
							Invoke-Command -Session $PSSession -ScriptBlock {Get-Content -ReadCount 1000 -Path $Using:RemoteFile} | Set-Content -Path $FilePath 
						} else {
						# ARTHIR - Copy the file that is created by the module.
							$null = Copy-Item -FromSession $PSSession -Path $RemoteFile.FullName -Destination $destdir
						}
					}
				}
			}
		}
		if ($rmdownload) {
            $rmdownloads = [string]$DirectivesHash.Get_Item("DOWNLOAD") -split ';'
            foreach ($dir in $rmdownloads) {
                if ($dir) {
#					Write-Host $dir
                    Invoke-Command -Session $PSSession -ScriptBlock { Get-ChildItem $using:dir -rec | Remove-Item}
                }
            }
        }
    }
    Remove-PSSession $PSSessions

    if ($Error) {
        $Error | Add-Content -Encoding $Encoding $ErrorLog
        $Error.Clear()
    }
    Write-Debug "Exiting $($MyInvocation.MyCommand)"    
}
$Runtime2 = ([String] (Get-Date -Format g))
Write-Verbose  "Start Time - $Runtime2"

function Push-Bindep {
<#
.SYNOPSIS
Attempts to copy required binaries to targets.
If a module depends on an external binary, the binary should be copied 
to .\Modules\bin\ and the module should reference the binary in the 
.NOTES section of the .SYNOPSIS as follows:
BINDEP .\Modules\bin\LOG-MD.exe

!! This directive is case-sensitve and must start the line !!

Some Modules may require multiple binary files, say an executable and 
required dlls. See the .\Modules\Disk\Get-FlsBodyFile.ps1 as an 
example. The BINDEP line in that module references 
.\Modules\bin\fls.zip. ARTHIR will copy that zip file to the targets, 
but the module itself handles the unzipping of the fls.zip file.

BINDEP must include the path to the binary, relative to ARTHIR.ps1's 
path.
#>
Param(
    [Parameter(Mandatory=$True,Position=0)]
        [Array]$Targets,
    [Parameter(Mandatory=$True,Position=1)]
        [String]$Module,
    [Parameter(Mandatory=$True,Position=2)]
        [String]$Bindep,
    [Parameter(Mandatory=$False,Position=3)]
        [System.Management.Automation.PSCredential]$Credential
        
)
    Write-Debug "Entering $($MyInvocation.MyCommand)"
    $Error.Clear()
    Write-Verbose "${Module} has dependency on ${Bindep}."
    if (-not (Test-Path("$Bindep"))) {
        Write-Verbose "${Bindep} not found in ${ModulePath}bin, skipping."
        "WARNING: ${Bindep} not found in ${ModulePath}\bin, skipping." | Add-Content -Encoding $Encoding $ErrorLog
        Continue
    }
    Write-Verbose "Attempting to copy ${Bindep} to targets..."
    $Targets | Foreach-Object { $Target = $_
    Try {
        if ($Credential) {
            [void] (New-PSDrive -PSProvider FileSystem -Name "ARTHIRDrive" -Root "\\$Target\ADMIN$" -Credential $Credential)
            Copy-Item "$Bindep" "ARTHIRDrive:"
            [void] (Remove-PSDrive -Name "ARTHIRDrive")
        } else {
            [void] (New-PSDrive -PSProvider FileSystem -Name "ARTHIRDrive" -Root "\\$Target\ADMIN$")
            Copy-Item "$Bindep" "ARTHIRDrive:"
            [void] (Remove-PSDrive -Name "ARTHIRDrive")
        }
    } Catch [Exception] {
        "Caught: $_" | Add-Content -Encoding $Encoding $ErrorLog
    }
        if ($Error) {
            "WARNING: Failed to copy ${Bindep} to ${Target}." | Add-Content -Encoding $Encoding $ErrorLog
            $Error | Add-Content -Encoding $Encoding $ErrorLog
            $Error.Clear()
        }
    }
    Write-Debug "Exiting $($MyInvocation.MyCommand)"    
}


function Send-File
{
	<#
	.SYNOPSIS
		This function sends a file (or folder of files recursively) to a destination WinRm session. This function was originally
		built by Lee Holmes (http://poshcode.org/2216) but has been modified to recursively send folders of files as well
		as to support UNC paths.

	.PARAMETER Path
		The local or UNC folder path that you'd like to copy to the session. This also support multiple paths in a comma-delimited format.
		If this is a UNC path, it will be copied locally to accomodate copying.  If it's a folder, it will recursively copy
		all files and folders to the destination.

	.PARAMETER Destination
		The local path on the remote computer where you'd like to copy the folder or file.  If the folder does not exist on the remote
		computer it will be created.

	.PARAMETER Session
		The remote session. Create with New-PSSession.

	.EXAMPLE
		$session = New-PSSession -ComputerName MYSERVER
		Send-File -Path C:\test.txt -Destination C:\ -Session $session

		This example will copy the file C:\test.txt to be C:\test.txt on the computer MYSERVER

	.INPUTS
		None. This function does not accept pipeline input.

	.OUTPUTS
		System.IO.FileInfo
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string[]]$Path,
		
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$Destination,
		
		[Parameter(Mandatory)]
		[System.Management.Automation.Runspaces.PSSession]$Session
	)
	process
	{
		foreach ($p in $Path)
		{
			try
			{
				if ($p.StartsWith('\\'))
				{
					Write-Verbose -Message "[$($p)] is a UNC path. Copying locally first"
					Copy-Item -Path $p -Destination ([environment]::GetEnvironmentVariable('TEMP', 'Machine'))
					$p = "$([environment]::GetEnvironmentVariable('TEMP', 'Machine'))\$($p | Split-Path -Leaf)"
				}
				if (Test-Path -Path $p -PathType Container)
				{
					Write-Log -Source $MyInvocation.MyCommand -Message "[$($p)] is a folder. Sending all files"
					$files = Get-ChildItem -Force -Path $p -File -Recurse
					$sendFileParamColl = @()
					foreach ($file in $Files)
					{
						$sendParams = @{
							'Session' = $Session
							'Path' = $file.FullName
						}
						if ($file.DirectoryName -ne $p) ## ARTHIR - It's a subdirectory
						{
							$subdirpath = $file.DirectoryName.Replace("$p\", '')
							$sendParams.Destination = "$Destination\$subDirPath"
						}
						else
						{
							$sendParams.Destination = $Destination
						}
						$sendFileParamColl += $sendParams
					}
					foreach ($paramBlock in $sendFileParamColl)
					{
						Send-File @paramBlock
					}
				}
				else
				{
					Write-Verbose -Message "Starting WinRM copy of [$($p)] to [$($Destination)]"
					# ARTHIR - Get the source file, and then get its contents
					$sourceBytes = [System.IO.File]::ReadAllBytes($p);
					$streamChunks = @();
					
					# ARTHIR - Now break it into chunks to stream.
					$streamSize = 1MB;
					for ($position = 0; $position -lt $sourceBytes.Length; $position += $streamSize)
					{
						$remaining = $sourceBytes.Length - $position
						$remaining = [Math]::Min($remaining, $streamSize)
						
						$nextChunk = New-Object byte[] $remaining
						[Array]::Copy($sourcebytes, $position, $nextChunk, 0, $remaining)
						$streamChunks +=, $nextChunk
					}
					$remoteScript = {
						if (-not (Test-Path -Path $using:Destination -PathType Container))
						{
							$null = New-Item -Path $using:Destination -Type Directory -Force
						}
						$fileDest = "$using:Destination\$($using:p | Split-Path -Leaf)"
						## ARTHIR - Create a new array to hold the file content - CODE LMD-ARTHIR
						$destBytes = New-Object byte[] $using:length
						$position = 0
						
						## ARTHIR - Go through the input, and fill in the new array of file content
						foreach ($chunk in $input)
						{
							[GC]::Collect()
							[Array]::Copy($chunk, 0, $destBytes, $position, $chunk.Length)
							$position += $chunk.Length
						}
						
						[IO.File]::WriteAllBytes($fileDest, $destBytes)
						
						Get-Item -Force $fileDest
						[GC]::Collect()
					}
					
					# ARTHIR - Stream the chunks into the remote script.
					$Length = $sourceBytes.Length
					$streamChunks | Invoke-Command -Session $Session -ScriptBlock $remoteScript
					Write-Verbose -Message "WinRM copy of [$($p)] to [$($Destination)] complete"
				}
			}
			catch
			{
				Write-Error $_.Exception.Message
			}
		}
	}
	
}


function Remove-Bindep {
<#
.SYNOPSIS
Attempts to remove binaries from targets when ARTHIR.ps1 is run with 
-rmbin switch.
ToDo: Fix this so it works even when Admin$ is not a valid share, as
is the case with default Azure VM configuration. Maybe more reliable
to Enter-PSSession for the host and Remove-Item.
#>
Param(
    [Parameter(Mandatory=$True,Position=0)]
        [Array]$Targets,
    [Parameter(Mandatory=$True,Position=1)]
        [String]$Module,
    [Parameter(Mandatory=$True,Position=2)]
        [String]$Bindep,
    [Parameter(Mandatory=$False,Position=3)]
        [System.Management.Automation.PSCredential]$Credential
)
    Write-Debug "Entering $($MyInvocation.MyCommand)"
    $Error.Clear()
    $Bindep = $Bindep.Substring($Bindep.LastIndexOf("\") + 1)
    Write-Verbose "Attempting to remove ${Bindep} from remote hosts."
    $Targets | Foreach-Object { $Target = $_
        if ($Credential) {
            [void] (New-PSDrive -PSProvider FileSystem -Name "ARTHIRDrive" -Root "\\$Target\ADMIN$" -Credential $Credential)
            Remove-Item "ARTHIRDrive:\$Bindep" 
            [void] (Remove-PSDrive -Name "ARTHIRDrive")
        } else {
            [void] (New-PSDrive -PSProvider FileSystem -Name "ARTHIRDrive" -Root "\\$Target\ADMIN$")
            Remove-Item "ARTHIRDrive:\$Bindep"
            [void] (Remove-PSDrive -Name "ARTHIRDrive")
        }
        
        if ($Error) {
            "WARNING: Failed to remove ${Bindep} to ${Target}." | Add-Content -Encoding $Encoding $ErrorLog
            $Error | Add-Content -Encoding $Encoding $ErrorLog
            $Error.Clear()
        }
    }
    Write-Debug "Exiting $($MyInvocation.MyCommand)"    
}

function List-Modules {
Param(
    [Parameter(Mandatory=$True,Position=0)]
        [String]$ModulePath
)
    Write-Debug "Entering $($MyInvocation.MyCommand)"
    $Error.Clear()

    ls $ModulePath | Foreach-Object { $dir = $_
        if ($dir.PSIsContainer -and ($dir.name -ne "bin" -or $dir.name -ne "Private")) {
            ls "${ModulePath}\${dir}\Get-*" | Foreach-Object { $file = $_
                $($dir.Name + "\" + (split-path -leaf $file))
            }
        } else {
            ls "${ModulePath}\Get-*" | Foreach-Object { $file = $_
                $file.Name
            }
        }
    }
    if ($Error) {
        # ARTHIR - Write the $Error to the $Errorlog
        $Error | Add-Content -Encoding $Encoding $ErrorLog
        $Error.Clear()
    }
    Write-Debug "Exiting $($MyInvocation.MyCommand)"    
}

function Set-ARTHIRPath {
    Write-Debug "Entering $($MyInvocation.MyCommand)"
    $Error.Clear()

    # ARTHIR - Update the path to include ARTHIR analysis script paths, if they aren't already
    $Invocation = (Get-Variable MyInvocation -Scope 1).Value
    $ARTHIRpath  = Split-Path $Invocation.MyCommand.Path
    $Paths      = ($env:Path).Split(";")

    if (-not($Paths -match [regex]::Escape("$ARTHIRpath\Analysis"))) {
        # ARTHIR - We want this one and it's not covered below, so...
        $env:Path = $env:Path + ";$ARTHIRpath\Analysis"
    }

    $AnalysisPaths = (ls -Recurse "$ARTHIRpath\Analysis" | Where-Object { $_.PSIsContainer } | Select-Object -ExpandProperty FullName)
    $AnalysisPaths | ForEach-Object {
        if (-not($Paths -match [regex]::Escape($_))) {
            $env:Path = $env:Path + ";$_"
        }
    }
    if ($Error) {
        # ARTHIR - Write the $Error to the $Errorlog
        $Error | Add-Content -Encoding $Encoding $ErrorLog
        $Error.Clear()
    }
    Write-Debug "Exiting $($MyInvocation.MyCommand)"    
}


function Get-Analysis {
<#
.SYNOPSIS
Runs analysis scripts as specified in .\Analyais\Analysis.conf
Saves output to AnalysisReports folder under the output path
Fails silently, but logs errors to Error.log file
#>
Param(
    [Parameter(Mandatory=$True,Position=0)]
        [String]$OutputPath,
    [Parameter(Mandatory=$True,Position=1)]
        [String]$StartingPath
)
    Write-Debug "Entering $($MyInvocation.MyCommand)"
    $Error.Clear()

    if (Get-Command -Name Logparser.exe) {
        $AnalysisScripts = @()
        $AnalysisScripts = Get-Content "$StartingPath\Analysis\Analysis.conf" | Foreach-Object { $_.Trim() } | Where-Object { $_ -gt 0 -and (!($_.StartsWith("#"))) }

        $AnalysisOutPath = $OutputPath + "\AnalysisReports\"
        [void] (New-Item -Path $AnalysisOutPath -ItemType Directory -Force)

        # ARTHIR - Get our DATADIR directive
        $DirectivesHash  = @{}
        $AnalysisScripts | Foreach-Object { $AnalysisScript = $_
            $DirectivesHash = Get-Directives $AnalysisScript -AnalysisPath
            $DataDir = $($DirectivesHash.Get_Item("DATADIR"))
            if ($DataDir) {
                if (Test-Path "$OutputPath$DataDir") {
                    Push-Location
                    Set-Location "$OutputPath$DataDir"
                    Write-Verbose "Running analysis script: ${AnalysisScript}"
                    $AnalysisFile = ((((($AnalysisScript -split "\\")[1]) -split "Get-")[1]) -split ".ps1")[0]
                    # ARTHIR - As of this writing, all analysis output files are tsv
                    & "$StartingPath\Analysis\${AnalysisScript}" | Set-Content -Encoding $Encoding ($AnalysisOutPath + $AnalysisFile + ".tsv")
                    Pop-Location
                } else {
                    "WARNING: Analysis: No data found for ${AnalysisScript}." | Add-Content -Encoding $Encoding $ErrorLog
                    Continue
                }
            } else {
                "WARNING: Analysis script, .\Analysis\${AnalysisScript}, missing # ARTHIR - DATADIR directive, skipping analysis." | Add-Content -Encoding $Encoding $ErrorLog
                Continue
            }        
        }
    } else {
        "ARTHIR could not find logparser.exe in path. Skipping Analysis." | Add-Content -Encoding $Encoding -$ErrorLog
    }
    # ARTHIR - Non-terminating errors can be checked via
    if ($Error) {
        # ARTHIR - Write the $Error to the $Errorlog
        $Error | Add-Content -Encoding $Encoding $ErrorLog
        $Error.Clear()
    }
    Write-Debug "Exiting $($MyInvocation.MyCommand)"    
} # ARTHIR - End Get-Analysis


# ARTHIR - Do not stop or report errors as a matter of course.   #
# ARTHIR - Instead write them out the error.log file and report  #
# ARTHIR - that there were errors at the end, if there were any. #
$Error.Clear()
$ErrorActionPreference = "SilentlyContinue"
$StartingPath = Get-Location | Select-Object -ExpandProperty Path

# ARTHIR - Create timestamped output path. Write transcript and error log #
# ARTHIR - to output path. Keep this first in the script so we can catch  #
# ARTHIR - errors in the error log of the output directory. We may create #
$Runtime = ([String] (Get-Date -Format yyyyMMddHHmmss))
[void] (New-Item -Path $OutputPath -ItemType Directory -Force) 

If ($Transcribe) {
    $TransFile = $OutputPath + ([string] (Get-Date -Format yyyyMMddHHmmss)) + ".log"
    [void] (Start-Transcript -Path $TransFile)
}
Set-Variable -Name ErrorLog -Value ($OutputPath + "Error.Log") -Scope Script

#if (Test-Path($ErrorLog)) {
# ARTHIR -    Remove-Item -Path $ErrorLog
#}
# ARTHIR - Done setting up output. #


# ARTHIR - Set the output encoding #
if ($Encoding) {
    Set-Variable -Name Encoding -Value $Encoding -Scope Script
} else {
    Set-Variable -Name Encoding -Value "Unicode" -Scope Script
}
# ARTHIR - End set output encoding #


# ARTHIR - Sanity check some parameters #
Write-Debug "Sanity checking parameters"
$Exit = $False
if ($TargetList -and -not (Test-Path($TargetList))) {
    "ERROR: User supplied TargetList, $TargetList, was not found." | Add-Content -Encoding $Encoding $ErrorLog
    $Exit = $True
}
if ($TargetCount -lt 0) {
    "ERROR: User supplied TargetCount, $TargetCount, was negative." | Add-Content -Encoding $Encoding $ErrorLog
    $Exit = $True
}
#TKTK Add test for $Credential
if ($Exit) {
    "ERROR: One or more errors were encountered with user supplied arguments. Exiting." | Add-Content -Encoding $Encoding $ErrorLog
    Exit
}
Write-Debug "Parameter sanity check complete."
# ARTHIR - End paramter sanity checks #


# ARTHIR - Update the user's path with ARTHIR Analysis paths. #
# ARTHIR - Exit if that's all they wanted us to do.          #
Set-ARTHIRPath
if ($UpdatePath) {
    # ARTHIR - User provided UpdatePath switch so
    # ARTHIR - exit after updating the path
    Exit
}
# ARTHIR - Done updating the path. #


# ARTHIR - If we're -Debug, show some settings. #
Write-Debug "`$ModulePath is ${ModulePath}."
Write-Debug "`$OutputPath is ${OutputPath}."
Write-Debug "`$ServerList is ${TargetList}."


# ARTHIR - Get our modules #
if ($ListModules) {
    # ARTHIR - User provided ListModules switch so exit
    # ARTHIR - after returning the full list of modules
    List-Modules ".\Modules\"
    Exit
}
# ARTHIR - Get-Modules reads the modules.conf file, if
# ARTHIR - it exists, otherwise will have same data as
# ARTHIR - List-Modules command above.
$Modules = Get-Modules -ModulePath $ModulePath
# ARTHIR - Done getting modules #


# ARTHIR - Get our analysis scripts #
if ($ListAnalysis) {
    # ARTHIR - User provided ListAnalysis switch so exit
    # ARTHIR - after returning a list of analysis scripts
    List-Modules ".\Analysis\"
    Exit
}


# ARTHIR - Get our targets. #
if ($TargetList) {
    $Targets = Get-Targets -TargetList $TargetList -TargetCount $TargetCount
} elseif ($Target) {
    $Targets = $Target
} else {
    Write-Verbose "No Targets specified. Building one requires RAST and will take some time."
    [void] (Load-AD)
    $Targets  = Get-Targets -TargetCount $TargetCount
}
# ARTHIR - Done getting targets #


# ARTHIR - Finally, let's gather some data. #
Get-TargetData -Targets $Targets -Modules $Modules -Credential $Credential -ThrottleLimit $ThrottleLimit
# ARTHIR - Done gathering data. #

# ARTHIR - Are we running analysis scripts? #
if ($Analysis) {
    Get-Analysis $OutputPath $StartingPath
}
# ARTHIR - Done running analysis #


# ARTHIR - Code to remove binaries from remote hosts
#if ($rmbin) {
# ARTHIR -    Remove-Bindep -Targets $Targets -Modules $Modules -Credential $Credential
#}
# ARTHIR - Done removing binaries #


# ARTHIR - Clean up #
$Runtime3 = ([String] (Get-Date -Format g))
Write-Verbose  "End Time - $Runtime3"
Exit
# ARTHIR - We're done. #
} Catch {
    ("Caught: {0}" -f $_)
} Finally {
    Exit-Script
}
