################################################################################
##  File:  Install-Miniconda.ps1
##  Desc:  Install the latest version of Miniconda and set $env:CONDA
##  Supply chain security: checksum validation
################################################################################

# Define variables
$condaDestination = "C:\Miniconda"
$installerName = "Miniconda3-latest-Windows-x86_64.exe"  # Update this if needed
$installerUrl = "https://repo.anaconda.com/miniconda/$installerName"

# Define a custom directory for the installer
$installerDir = "C:\MinicondaInstaller"
$installerPath = "$installerDir\$installerName"

# Ensure the custom installer directory exists
if (!(Test-Path $installerDir)) {
    Write-Host "Creating installer directory: $installerDir"
    New-Item -ItemType Directory -Path $installerDir -Force
}

#region Supply chain security
$distributorFileHash = $null
$response = Invoke-WebRequest -Uri 'https://repo.anaconda.com/miniconda/' -UseBasicParsing
$pattern = "$installerName.*?([a-fA-F0-9]{64})"
$match = [regex]::Match($response.Content, $pattern)

if ($match.Success) {
    $distributorFileHash = $match.Groups[1].Value
} else {
    throw "Unable to find checksum for $installerName in https://repo.anaconda.com/miniconda/"
}
#endregion

# Download installer
Write-Host "Downloading Miniconda installer to $installerPath..."
Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath

# SHA256 validation block
Write-Host "Validating SHA256 checksum..."
$calculatedHash = (Get-FileHash -Path $installerPath -Algorithm SHA256).Hash.ToLower()

if ($calculatedHash -ne $distributorFileHash.ToLower()) {
    throw "SHA256 hash mismatch! Expected: $distributorFileHash, Got: $calculatedHash"
} else {
    Write-Host "SHA256 hash verified."
}

# Install Miniconda
Install-Binary `
    -Url "https://repo.anaconda.com/miniconda/${installerName}" `
    -InstallArgs @("/S", "/AddToPath=0", "/RegisterPython=0", "/D=$condaDestination") `
    -ExpectedSHA256Sum $distributorFileHash

[Environment]::SetEnvironmentVariable("CONDA", $condaDestination, "Machine")


Invoke-PesterTests -TestFile "Miniconda"

