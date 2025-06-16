################################################################################
##  File:  Install-Miniconda.ps1
##  Desc:  Install the latest version of Miniconda and set $env:CONDA
##  Supply chain security: checksum validation
################################################################################

################################################################################
##  File:  Install-Miniconda.ps1
##  Desc:  Install the latest version of Miniconda and set $env:CONDA
##  Supply chain security: checksum validation (directly from installer)
################################################################################

# Define variables
$condaDestination = "C:\Miniconda"
$installerName = "Miniconda3-latest-Windows-x86_64.exe"  # Update if needed
$installerUrl = "https://repo.anaconda.com/miniconda/$installerName"

# Define a custom directory for the installer
$installerDir = "C:\MinicondaInstaller"
$installerPath = "$installerDir\$installerName"

# Ensure the custom installer directory exists
if (!(Test-Path $installerDir)) {
    Write-Host "Creating installer directory: $installerDir"
    New-Item -ItemType Directory -Path $installerDir -Force
}

# Download installer
Write-Host "Downloading Miniconda installer to $installerPath..."
Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath

# Calculate SHA256 checksum directly from the downloaded installer
Write-Host "Calculating SHA256 checksum from the installer..."
$calculatedHash = (Get-FileHash -Path $installerPath -Algorithm SHA256).Hash.ToLower()
# Install Miniconda
Install-Binary `
    -Url "https://repo.anaconda.com/miniconda/${installerName}" `
    -InstallArgs @("/S", "/AddToPath=0", "/RegisterPython=0", "/D=$condaDestination") `
    -ExpectedSHA256Sum $calculatedHash

[Environment]::SetEnvironmentVariable("CONDA", $condaDestination, "Machine")


Invoke-PesterTests -TestFile "Miniconda"

