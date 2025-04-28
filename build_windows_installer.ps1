# Horus Windows Installer Build Script
# This script builds Horus and creates a Windows installer

# Set error action preference to stop on any error
$ErrorActionPreference = "Stop"

# Configuration variables
$BuildDir = ".\build_output"
$InstallerDir = ".\installer"
$ReleaseVersion = "1.0.0"

Write-Host "=== Horus Windows Installer Build Script ===" -ForegroundColor Cyan
Write-Host "This script will build Horus and create a Windows installer" -ForegroundColor Cyan
Write-Host ""

# Check for required tools
Write-Host "Checking for required tools..." -ForegroundColor Yellow

# Check for Node.js
try {
    $nodeVersion = node -v
    Write-Host "Node.js found: $nodeVersion" -ForegroundColor Green
} catch {
    Write-Host "Node.js not found. Please install Node.js before continuing." -ForegroundColor Red
    exit 1
}

# Check for Yarn
try {
    $yarnVersion = yarn -v
    Write-Host "Yarn found: $yarnVersion" -ForegroundColor Green
} catch {
    Write-Host "Yarn not found. Please install Yarn before continuing." -ForegroundColor Red
    exit 1
}

# Check for Git
try {
    $gitVersion = git --version
    Write-Host "Git found: $gitVersion" -ForegroundColor Green
} catch {
    Write-Host "Git not found. Please install Git before continuing." -ForegroundColor Red
    exit 1
}

# Check for Inno Setup (required for Windows installer)
$innoSetupPath = "C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
if (Test-Path $innoSetupPath) {
    Write-Host "Inno Setup found" -ForegroundColor Green
} else {
    Write-Host "Inno Setup not found. Please install Inno Setup 6 before continuing." -ForegroundColor Red
    Write-Host "Download from: https://jrsoftware.org/isdl.php" -ForegroundColor Yellow
    exit 1
}

# Create directories
Write-Host "Creating build directories..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path $BuildDir | Out-Null
New-Item -ItemType Directory -Force -Path $InstallerDir | Out-Null

# Set environment variables for build
$env:SHOULD_BUILD = "yes"
$env:VSCODE_QUALITY = "stable"
$env:OS_NAME = "windows"
$env:VSCODE_ARCH = "x64"
$env:CI_BUILD = "no"
$env:DISABLE_UPDATE = "no"

# Clone VS Code repository if not already done
if (-not (Test-Path ".\vscode")) {
    Write-Host "Cloning VS Code repository..." -ForegroundColor Yellow
    git clone https://github.com/microsoft/vscode.git
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to clone VS Code repository" -ForegroundColor Red
        exit 1
    }
}

# Apply Horus customizations
Write-Host "Applying Horus customizations..." -ForegroundColor Yellow

# Run the build script
Write-Host "Building Horus..." -ForegroundColor Yellow
try {
    # First, make sure we have the right permissions to run the script
    if (Test-Path ".\build.sh") {
        # On Windows with Git Bash installed, we can use this approach
        $bashPath = "C:\Program Files\Git\bin\bash.exe"
        if (Test-Path $bashPath) {
            & $bashPath -c "./build.sh"
        } else {
            Write-Host "Git Bash not found. Please install Git with Bash or run the build manually." -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "build.sh not found. Please make sure you're in the correct directory." -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "Build failed: $_" -ForegroundColor Red
    exit 1
}

# Check if the build was successful
if (-not (Test-Path ".\VSCode-win32-x64")) {
    Write-Host "Build output not found. The build may have failed." -ForegroundColor Red
    exit 1
}

# Create Windows installer using Inno Setup
Write-Host "Creating Windows installer..." -ForegroundColor Yellow

# Create Inno Setup script
$innoSetupScript = @"
#define MyAppName "Horus"
#define MyAppVersion "$ReleaseVersion"
#define MyAppPublisher "Horus Team"
#define MyAppURL "https://github.com/DheerajNarlajarla/Horus"
#define MyAppExeName "Horus.exe"
#define SourcePath "VSCode-win32-x64"

[Setup]
AppId={{763CBF88-25C6-4B10-952F-326AE657F16B}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
LicenseFile=LICENSE
OutputDir=$InstallerDir
OutputBaseFilename=Horus-Setup-{#MyAppVersion}
SetupIconFile=icons\stable\horus.ico
Compression=lzma
SolidCompression=yes
WizardStyle=modern
ChangesAssociations=yes
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
Name: "quicklaunchicon"; Description: "{cm:CreateQuickLaunchIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked; OnlyBelowVersion: 6.1; Check: not IsAdminInstallMode

[Files]
Source: "{#SourcePath}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon
Name: "{userappdata}\Microsoft\Internet Explorer\Quick Launch\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: quicklaunchicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
"@

# Save the Inno Setup script
$innoSetupScriptPath = ".\horus_installer.iss"
$innoSetupScript | Out-File -FilePath $innoSetupScriptPath -Encoding utf8

# Run Inno Setup compiler
Write-Host "Compiling installer..." -ForegroundColor Yellow
& $innoSetupPath $innoSetupScriptPath

if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to create installer" -ForegroundColor Red
    exit 1
}

Write-Host "Installer created successfully!" -ForegroundColor Green
Write-Host "You can find the installer at: $InstallerDir\Horus-Setup-$ReleaseVersion.exe" -ForegroundColor Cyan

# Cleanup
Write-Host "Cleaning up..." -ForegroundColor Yellow
Remove-Item -Path $innoSetupScriptPath -Force

Write-Host "Done!" -ForegroundColor Green
