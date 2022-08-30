# Overview

Execute this from within Powershell: `_deploy.ps1`

The very first time you run `_deploy.ps1`, the dotnet build command hangs for ~10 minutes *after it's done with the build*. Thereafter, it doesn't consistenly have that problem, but when it happens, it appears to only be after source code is changed.

## Notes
 * The project is the "empty Asp.Net core" project from VS 2022, targeting .Net 6.0. (I unchecked the https checkbox in the wizard, though.)
 * This ALWAYS happens when building in Azure using a hosted pool that uses `vmImage: "windows-2022"` (since *every* build is always the "first build"). See the sample `azure-pipelines.yml` file.
 * The build does **not** hang when running `_deploy.ps1` from Linux; this is only a Windows thing.
 * It doesn't seem to matter what runtime Id is the target of your build.

# Explanation/Resolution
A number of months ago, it was pointed out to me that the problem is how the `Start-Process` cmdlet's `-Wait` switch works, in connection with how the `dotnet` program works. In Windows, `-Wait` will wait for *all* descendant processes, not just the one being started. And `dotnet` will often spawn its own, detached child processes (for performance/caching reasons). On Linux, `-Wait` will only wait on the process that was started by the cmdlet. So `Start-Process` ends with the build on Linux. But on Windows, `Start-Process` also waits for the background/TSR processes that stick around for ~10 minutes, just in case you want to do another build.

One solution is to avoid `Start-Process` and use the call operator (`&`).
