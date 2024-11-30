################################################################################
##  File:  Install-PostgreSQL.ps1
##  Desc:  Install PostgreSQL along with required C++ binaries
################################################################################

# Define user and password for PostgreSQL database
$pgUser = "postgres"
$pgPwd = "root"

# Prepare environment variable for validation
[Environment]::SetEnvironmentVariable("PGUSER", $pgUser, "Machine")
[Environment]::SetEnvironmentVariable("PGPASSWORD", $pgPwd, "Machine")

# Install Visual C++ Redistributables (x86 and x64)
$vcFiles = @(
    @{
        Url = "https://aka.ms/vs/17/release/vc_redist.x64.exe"
        ExpectedHash = "245D262748012A4FE6CE8BA6C951A4C4AFBC3E5D" 
    },
    @{
        Url = "https://aka.ms/vs/17/release/vc_redist.x86.exe"
        ExpectedHash = "245D262748012A4FE6CE8BA6C951A4C4AFBC3E5D" 
    }
)

foreach ($vcFile in $vcFiles) {
    $url = $vcFile.Url
    $expectedHash = $vcFile.ExpectedHash
    
    $installer = Join-Path $env:TEMP (Split-Path $url -Leaf)
    Write-Host "Downloading $url ..."
    Invoke-WebRequest -Uri $url -OutFile $installer

    # Verify SHA256 hash of the downloaded file
    $downloadedHash = (Get-FileHash -Path $installer -Algorithm SHA256).Hash.ToLower()
    if ($downloadedHash -ne $expectedHash.ToLower()) {
        Write-Host "Hash mismatch for $installer. Expected: $expectedHash, but got: $downloadedHash. Exiting."
        exit 1
    }

    Write-Host "Installing $installer ..."
    Start-Process -FilePath $installer -ArgumentList "/install", "/quiet", "/norestart" -Wait

    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to install $installer. Exiting."
        exit 1
    }

    Write-Host "Removing $installer ..."
    Remove-Item $installer
}

# Define the installer URL
$toolsetVersion = (Get-ToolsetContent).postgresql.version
if ($null -ne ($toolsetVersion | Select-String -Pattern '\d+\.\d+\.\d+')) {
    $majorVersion = ([version]$toolsetVersion).Major
    $minorVersion = ([version]$toolsetVersion).Minor
    $patchVersion = ([version]$toolsetVersion).Build
    $installerUrl = "https://get.enterprisedb.com/postgresql/postgresql-$majorVersion.$minorVersion-$patchVersion-windows-x64.exe"
} else {
    # Define latest available version to install based on version specified in the toolset
    $getPostgreReleases = Invoke-WebRequest -Uri "https://git.postgresql.org/gitweb/?p=postgresql.git;a=tags" -UseBasicParsing
    # Getting all links matched to the pattern (e.g.a=log;h=refs/tags/REL_14)
    $targetReleases = $getPostgreReleases.Links.href | Where-Object { $_ -match "a=log;h=refs/tags/REL_$toolsetVersion" }
    [Int32] $outNumber = $null
    $minorVersions = @()
    foreach ($release in $targetReleases) {
        $version = $release.split('/')[-1]
        # Checking if the latest symbol of the release version is actually a number. If yes, add to $minorVersions array
        if ([Int32]::TryParse($($version.Split('_')[-1]), [ref] $outNumber)) {
            $minorVersions += $outNumber
        }
    }
    # Sorting and getting the last one
    $targetMinorVersions = ($minorVersions | Sort-Object)[-1]

    # In order to get rid of error messages (we know we will have them), force ErrorAction to SilentlyContinue
    $errorActionOldValue = $ErrorActionPreference
    $ErrorActionPreference = 'SilentlyContinue'

    # Install latest PostgreSQL
    # Starting from number 9 and going down, check if the installer is available. If yes, break the loop.
    # If an installer with $targetMinorVersions is not to be found, the $targetMinorVersions will be decreased by 1
    $increment = 9
    do {
        $url = "https://get.enterprisedb.com/postgresql/postgresql-$toolsetVersion.$targetMinorVersions-$increment-windows-x64.exe"
        try {
            $checkAccess = Invoke-WebRequest -Uri $url -UseBasicParsing -Method Head
            if ($checkAccess.StatusCode -eq 200) {
                $installerUrl = $url
                break
            }
        } catch {
            if ($increment -eq 0) {
                $increment = 9
                $targetMinorVersions--
            } else {
                $increment--
            }
        }
    } while ($true)
}

# Return the previous value of ErrorAction
$ErrorActionPreference = $errorActionOldValue

# Install PostgreSQL
Write-Host "Starting PostgreSQL installation ..."
$installerArgs = @(
    "--install_runtimes 0",
    "--superpassword root",
    "--enable_acledit 1",
    "--unattendedmodeui none",
    "--mode unattended",
    "--debuglevel 4"
)

Install-Binary `
    -Url $installerUrl `
    -InstallArgs $installerArgs `
    -ErrorAction Stop

if ($LASTEXITCODE -ne 0) {
    Write-Host "PostgreSQL installation failed with exit code $LASTEXITCODE."
    exit 1
}

# Get Path to pg_ctl.exe
$pgService = Get-CimInstance Win32_Service -Filter "Name LIKE 'postgresql-%'"
if ($pgService -eq $null) {
    Write-Host "PostgreSQL service not found. Exiting."
    exit 1
}
$pgPath = $pgService.PathName

# Display the retrieved path
Write-Host "PostgreSQL service path: $pgPath"

# Check if $pgPath is null
if ($pgPath -eq $null) {
    Write-Host "PostgreSQL service path is null. Exiting."
    exit 1
}

# Parse output of command above to obtain pure path
try {
    $pgBin = Split-Path -Path $pgPath.split('"')[1]
    Write-Host "PostgreSQL binary path: $pgBin"
    $pgRoot = Split-Path -Path $pgPath.split('"')[5]
    Write-Host "PostgreSQL root path: $pgRoot"
    $pgData = Join-Path $pgRoot "data"
    Write-Host "PostgreSQL data path: $pgData"
} catch {
    Write-Host "Failed to parse PostgreSQL service path. Error: $_"
    exit 1
}

# Validate PostgreSQL installation
$pgReadyPath = Join-Path $pgBin "pg_isready.exe"
Write-Host "Path to pg_isready: $pgReadyPath"
$pgReady = Start-Process -FilePath $pgReadyPath -Wait -PassThru
$exitCode = $pgReady.ExitCode

if ($exitCode -ne 0) {
    Write-Host "PostgreSQL is not ready. Exit code: $exitCode"
    exit $exitCode
}

# Add PostgreSQL environment variables
[Environment]::SetEnvironmentVariable("PGBIN", $pgBin, "Machine")
[Environment]::SetEnvironmentVariable("PGROOT", $pgRoot, "Machine")
[Environment]::SetEnvironmentVariable("PGDATA", $pgData, "Machine")

# Stop and disable PostgreSQL service
$pgService = Get-Service -Name postgresql*
Stop-Service $pgService
$pgService | Set-Service -StartupType Disabled

Invoke-PesterTests -TestFile "Databases" -TestName "PostgreSQL"
