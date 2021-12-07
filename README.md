# Overview

Execute this from within Powershell: `_deploy.ps1`

The very first time you run `_deploy.ps1`, the dotnet build command hangs for ~10 minutes *after it's done with the build*. Thereafter, it doesn't consistenly have that problem, but when it happens, it appears to only be after source code is changed.

## Notes
 * The project is the "empty Asp.Net core" project from VS 2022, targeting .Net 6.0. (I unchecked the https checkbox in the wizard, though.)
 * This ALWAYS happens when building in Azure using a hosted pool that uses `vmImage: "windows-2022"` (since *every* build is always the "first build"). See the sample `azure-pipelines.yml` file.
 * The build does **not** hang when running `_deploy.ps1` from Linux; this is only a Windows thing.
 * It doesn't seem to matter what runtime Id is the target of your build.

