<#
	.SYNOPSIS 
	Builds the project and places the build output (artifacts) in the BuildArtifacts sub-folder.

	.NOTES
	I.e.
		Cleans the final-output folder
		Cleans the build-intermediates folder.
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

	.PARAMETER Clean
	Specify this switch to do a "dotnet clean" before doing the build.
	This isn't helpful in automated builds where there isn't any build-intermediates lying around that could affect the build.
	(I.e. If there are no "bin" or "obj" folders, the "clean" will report a failure, which is just useless noise.)

	.PARAMETER CopyOutputToPath
	Indicates where to copy the build output/artifacts after a successful build. Make sure this is valid based on your platform (Windows vs *Nix).
	
#>

param(
	[string]$RuntimeId = "win10-x64" 
	, [string]$FrameworkId = "net6.0"
	, [switch]$SelfContained 
	, [switch]$Clean
	, [string]$CopyOutputToPath = ""
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


if ($Clean) {
	Write-Output "Cleaning '$_ProjectFile' build cache ..."; 
	Start-Process -FilePath "dotnet" -Wait -NoNewWindow -ArgumentList @(
		, "clean" 
		, "`"$_ProjectFile`""
		# don't specify --output; we want it to clean the default "bin" and "obj" directories.
		, "--configuration Release"
		, "--framework `"$FrameworkId`"" 
		, "--runtime `"$RuntimeId`"" # (instead of "-a" or "-os") 
		, "--nologo" # reduce noise
	);
	Write-Output "";
}


# https://docs.microsoft.com/en-us/dotnet/core/deploying/deploy-with-cli
# https://docs.microsoft.com/en-us/dotnet/core/deploying/single-file
# https://docs.microsoft.com/en-us/dotnet/core/deploying/trim-self-contained  (We're not going to bother, for now: 2021-10)
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
	#, "-p:`"PublishTrimmed=true`"" # This makes the build take a LOT longer, you get a LOT of warnings about possible issues, and it's smaller to just do !SelfContained.
);
Write-Output "";


if (!$CopyOutputToPath) { # catches $null and ""
	Write-Output "No `$CopyOutputToPath directory specified; skipping copy of build artifacts.";
} elseif (Test-Path -Path $CopyOutputToPath) {
	Write-Output "Copying build artifact(s) to '$CopyOutputToPath' ...";
	Copy-Item -Path ([IO.Path]::Combine($_OutputDir, "*.exe")) -Destination $CopyOutputToPath -Verbose; # Verbose so the output shows exactly what went where.
} else {
	Write-Output "Invalid directory specified in `$CopyOutputToPath. Cannot copy build artifact(s) to '$CopyOutputToPath' ";
}


Write-Output "";
Write-Output "Done: Success!";
Write-Output "";
