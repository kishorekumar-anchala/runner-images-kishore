################################################################################
##  File:  Install-Miniconda.ps1
##  Desc:  Install the latest version of Miniconda and set $env:CONDA
##  Supply chain security: checksum validation
################################################################################

$condaDestination = "C:\Miniconda"
$installerName = "Miniconda3-latest-Windows-x86_64.exe"

Install-Binary `
    -Url "https://repo.anaconda.com/miniconda/${installerName}" `
    -InstallArgs @("/S", "/AddToPath=0", "/RegisterPython=0", "/D=$condaDestination") `
    -ExpectedSHA256Sum "ea482f35b4861f047dc525c1e8dc645cc761a5460a121caf726dec098c5804de"

[Environment]::SetEnvironmentVariable("CONDA", $condaDestination, "Machine")

Invoke-PesterTests -TestFile "Miniconda"
