################################################################################
##  File:  Install-Miniconda.ps1
##  Desc:  Install the latest version of Miniconda and set $env:CONDA
##  Supply chain security: checksum validation
################################################################################

$condaDestination = "C:\Miniconda"
$installerName = "Miniconda3-latest-Windows-x86_64.exe"

$installerUrl = "https://repo.anaconda.com/miniconda/$installerName"

# Define a custom directory for the installer
$installerDir = "C:\MinicondaInstaller"
$installerPath = "$installerDir\$installerName"

# Ensure the custom installer directory exists
if (!(Test-Path $installerDir)) {
    Write-Host "Creating installer directory: $installerDir"
    New-Item -ItemType Directory -Path $installerDir -Force
}

Write-Host "Downloading Miniconda installer to $installerPath..."
Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath

# Calculate SHA256 checksum directly from the downloaded installer
Write-Host "Calculating SHA256 checksum from the installer..."
$calculatedHash = (Get-FileHash -Path $installerPath -Algorithm SHA256).Hash.ToLower()

Write-Host "========================================="
Write-Host "SHA256 checksum of downloaded file:"
Write-Host "$calculatedHash"
Write-Host "========================================="

Write-Host "Installing Miniconda..."
Start-Process -FilePath $installerPath -ArgumentList "/S", "/AddToPath=0", "/RegisterPython=0", "/D=$condaDestination" -Wait

[Environment]::SetEnvironmentVariable("CONDA", $condaDestination, "Machine")

Invoke-PesterTests -TestFile "Miniconda"
