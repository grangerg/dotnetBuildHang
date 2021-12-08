<#
	.SYNOPSIS 
	Builds the project and places the build output (artifacts) in the BuildArtifacts sub-folder.

	.NOTES
	I.e.
		Cleans the final-output folder
		Restores (Nuget packages)
		Builds in Release mode
		Finally, deploys/publishes (whatever you're calling it this week)

	.PARAMETER RuntimeId
	The Id of the runtime you want to target with the build.
	E.g. win10-x64, linux-musl-x64 (Alpine Linux), linux-x64 
	https://docs.microsoft.com/en-us/dotnet/core/rid-catalog

	.PARAMETER FrameworkId
	The .Net framework to target. E.g. net3.0, net3.1, net5.0, net6.0

	.PARAMETER SelfContained
	This controls whether the .Net runtime will be packaged into the final executable. All other "single-executable" option are used/on, regardless this setting. 
	True/Present - The runtime is packaged into the final executable.
	False - The .Net runtime must be made available where the executable is ultimately published or it will not be able to run.

#>

param(
	[string]$RuntimeId = "win10-x64" 
	, [string]$FrameworkId = "net6.0"
	, [switch]$SelfContained 
)


$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop; # Makes it so we don't have to code anything special to be friendly to the automated build process.
Push-Location $PSScriptRoot; #Make the script folder the current working folder, so it doesn't matter where it's called from.
$_ProjectFile = [IO.Path]::Combine($Pwd.Path, "Example.csproj");
$_OutputDir = [IO.Path]::Combine($Pwd.Path, "BuildArtifacts");

Write-Output "";
Write-Output "RuntimeId: $RuntimeId";
Write-Output "FrameworkId: $FrameworkId";
Write-Output "SelfContained: $SelfContained";
Write-Output "OutputDir: $_OutputDir";

if (Test-Path -Path $_OutputDir) {
	Write-Output "Cleaning output directory '$_OutputDir' ...";
	Remove-Item ([IO.Path]::Combine($_OutputDir, "*")) -Recurse -Force;
} else {
	Write-Output "Creating output directory '$_OutputDir' ...";
	New-Item -Type Directory -Force -Path $_OutputDir;
}
Write-Output "";


Write-Output "Publishing '$_ProjectFile' in RELEASE mode ..."; 
Start-Process -FilePath "dotnet" -Wait -NoNewWindow -ArgumentList @(
	, "publish" # https://docs.microsoft.com/en-us/dotnet/core/tools/dotnet-publish
	, "`"$_ProjectFile`""
	, "--output `"$_OutputDir`"" 
	, "--configuration Release"
	, "--framework `"$FrameworkId`"" 
	, "--runtime `"$RuntimeId`"" # (instead of "-a" or "-os") In .Net 6, it's a warning to not also indicate "(not) self-contained".
	, "--nologo" # reduce noise
	, "--self-contained $SelfContained" # include the runtime in the final output.
	# multiple so we can comment each; you can also do a single "-p" and semi-colon-delimit the options.
	, "-p:`"Platform=x64`"" # Project options: "Platform">>>"PlatformTarget" in the project file; technically not needed when there's only one defined in the file.
	, "-p:`"PublishSingleFile=true`"" # We want a single .exe, not a ton of .dll files; these get extracted into memory at runtime, nowadays.
	, "-p:`"IncludeNativeLibrariesForSelfExtract=true`"" # Put those ~5 "native" dlls into the final .exe also.
	, "-p:`"DebugType=embedded`"" # put the .pdb files in the .exe also
	, "-p:`"PublishReadyToRun=true`"" # improve startup performance at the cost of build performance.
	, "-bl" # Generate binlogs
);
Write-Output "";


Write-Output "";
Write-Output "Done: Success!";
Write-Output "";
