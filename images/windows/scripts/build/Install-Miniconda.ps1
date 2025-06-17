################################################################################
##  File:  Install-Miniconda.ps1
##  Desc:  Install the latest version of Miniconda and set $env:CONDA
##  Supply chain security: checksum validation before installation
################################################################################

# Define variables
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

# Download installer
Write-Host "Downloading Miniconda installer to $installerPath..."
Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath

# Fetch official checksum using ConvertFrom-HTML
Write-Host "Fetching official checksum from Miniconda repository..."
$distributorFileHash = $null
$checksums = (ConvertFrom-HTML -Uri 'https://repo.anaconda.com/miniconda/').SelectNodes('//html/body/table/tr')

foreach ($node in $checksums) {
    if ($node.ChildNodes[1].InnerText -eq $installerName) {
        $distributorFileHash = $node.ChildNodes[7].InnerText
    }
}

if ($null -eq $distributorFileHash) {
    throw "Unable to find checksum for $installerName in https://repo.anaconda.com/miniconda/"
}


# Calculate SHA256 checksum from the downloaded installer
$calculatedHash = (Get-FileHash -Path $installerPath -Algorithm SHA256).Hash.ToLower()

# Validate checksum before installation
if ($calculatedHash -ne $distributorFileHash.ToLower()) {
    throw "SHA256 hash mismatch! Expected: $distributorFileHash, Got: $calculatedHash"
} else {
    Write-Host "SHA256 hash verified. Proceeding with installation..."
}

# Install Miniconda
Start-Process -FilePath $installerPath -ArgumentList "/S", "/AddToPath=0", "/RegisterPython=0", "/D=$condaDestination" -Wait


[Environment]::SetEnvironmentVariable("CONDA", $condaDestination, "Machine")

# Cleanup: Delete installer file and folder
Remove-Item -Path $installerPath -Force
Remove-Item -Path $installerDir -Recurse -Force

Invoke-PesterTests -TestFile "Miniconda"
