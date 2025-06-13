################################################################################
##  File:  Install-Miniconda.ps1
##  Desc:  Install the latest version of Miniconda and set $env:CONDA
##  Supply chain security: checksum validation
################################################################################

$condaDestination = "C:\Miniconda"
$installerUrl = "https://repo.anaconda.com/miniconda/$installerName"
$installerPath = "$env:TEMP\$installerName"

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
Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath

# SHA256 validation block (added)
$calculatedHash = (Get-FileHash -Path $installerPath -Algorithm SHA256).Hash.ToLower()

if ($calculatedHash -ne $distributorFileHash.ToLower()) {
    throw "SHA256 hash mismatch! Expected: $distributorFileHash, Got: $calculatedHash"
} else {
    Write-Host "SHA256 hash verified."
}

Install-Binary `
    -Url "https://repo.anaconda.com/miniconda/${installerName}" `
    -InstallArgs @("/S", "/AddToPath=0", "/RegisterPython=0", "/D=$condaDestination") `
    -ExpectedSHA256Sum $distributorFileHash

[Environment]::SetEnvironmentVariable("CONDA", $condaDestination, "Machine")

Invoke-PesterTests -TestFile "Miniconda"
