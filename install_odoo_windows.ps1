# Odoo 18.0 Windows Installation Script (PowerShell)
# Created: August 21, 2025
# Based on successful macOS installation

param(
    [string]$InstallDir = "C:\odoo-18.0",
    [switch]$SkipPrerequisites,
    [switch]$SkipDownload
)

# Check if running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "This script requires Administrator privileges. Please run PowerShell as Administrator."
    exit 1
}

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "            ODOO 18.0 WINDOWS INSTALLATION SCRIPT" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Installation directory: $InstallDir" -ForegroundColor Yellow
Write-Host ""

# Function to check if command exists
function Test-Command {
    param($Command)
    try {
        if (Get-Command $Command -ErrorAction SilentlyContinue) {
            return $true
        }
    }
    catch {
        return $false
    }
    return $false
}

# Function to install via winget with error handling
function Install-Package {
    param($PackageName, $DisplayName)
    
    Write-Host "Installing $DisplayName..." -ForegroundColor Yellow
    try {
        $result = winget install $PackageName --silent --accept-source-agreements --accept-package-agreements 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ $DisplayName installed successfully" -ForegroundColor Green
            return $true
        } else {
            Write-Warning "Failed to install $DisplayName via winget"
            return $false
        }
    }
    catch {
        Write-Warning "Error installing $DisplayName: $_"
        return $false
    }
}

# Create installation directory
Write-Host "[1/10] Creating installation directory..." -ForegroundColor Cyan
if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    Write-Host "✅ Created directory: $InstallDir" -ForegroundColor Green
} else {
    Write-Host "✅ Directory already exists: $InstallDir" -ForegroundColor Green
}

Set-Location $InstallDir

if (-not $SkipPrerequisites) {
    # Install Python 3.11
    Write-Host "[2/10] Installing Python 3.11..." -ForegroundColor Cyan
    if (-not (Test-Command "python")) {
        if (-not (Install-Package "Python.Python.3.11" "Python 3.11")) {
            Write-Error "Failed to install Python. Please install manually from python.org"
            exit 1
        }
        # Refresh environment
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    } else {
        Write-Host "✅ Python already installed: $(python --version)" -ForegroundColor Green
    }

    # Install Git
    Write-Host "[3/10] Installing Git..." -ForegroundColor Cyan
    if (-not (Test-Command "git")) {
        if (-not (Install-Package "Git.Git" "Git")) {
            Write-Error "Failed to install Git. Please install manually from git-scm.com"
            exit 1
        }
        # Refresh environment
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    } else {
        Write-Host "✅ Git already installed: $(git --version)" -ForegroundColor Green
    }

    # Install PostgreSQL
    Write-Host "[4/10] Installing PostgreSQL..." -ForegroundColor Cyan
    if (-not (Test-Command "psql")) {
        if (-not (Install-Package "PostgreSQL.PostgreSQL.14" "PostgreSQL 14")) {
            Write-Warning "Failed to install PostgreSQL via winget"
            Write-Host "Please install PostgreSQL 14 manually from postgresql.org" -ForegroundColor Red
            Write-Host "Set the postgres user password to 'postgres'" -ForegroundColor Yellow
        } else {
            Write-Host "✅ PostgreSQL installed successfully" -ForegroundColor Green
        }
        # Refresh environment
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    } else {
        Write-Host "✅ PostgreSQL already installed: $(psql --version)" -ForegroundColor Green
    }

    # Install Build Tools
    Write-Host "[5/10] Installing Visual Studio Build Tools..." -ForegroundColor Cyan
    try {
        $buildTools = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -like "*Visual Studio*Build Tools*" -or $_.Name -like "*Microsoft Visual C++*" }
        if (-not $buildTools) {
            if (-not (Install-Package "Microsoft.VisualStudio.2022.BuildTools" "Visual Studio Build Tools")) {
                Write-Warning "Failed to install Build Tools via winget"
                Write-Host "Please install Visual Studio Build Tools manually" -ForegroundColor Yellow
                Write-Host "Download from: https://visualstudio.microsoft.com/visual-cpp-build-tools/" -ForegroundColor Yellow
            } else {
                Write-Host "✅ Visual Studio Build Tools installed" -ForegroundColor Green
            }
        } else {
            Write-Host "✅ Build Tools already available" -ForegroundColor Green
        }
    }
    catch {
        Write-Warning "Could not verify Build Tools installation"
    }

    # Install Node.js
    Write-Host "[6/10] Installing Node.js..." -ForegroundColor Cyan
    if (-not (Test-Command "node")) {
        if (-not (Install-Package "OpenJS.NodeJS" "Node.js")) {
            Write-Error "Failed to install Node.js. Please install manually from nodejs.org"
            exit 1
        }
        # Refresh environment
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    } else {
        Write-Host "✅ Node.js already installed: $(node --version)" -ForegroundColor Green
    }

    # Install SASS
    Write-Host "Installing SASS globally..." -ForegroundColor Yellow
    try {
        npm install -g sass 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ SASS installed successfully: $(sass --version)" -ForegroundColor Green
        } else {
            Write-Warning "Failed to install SASS globally"
        }
    }
    catch {
        Write-Warning "Error installing SASS: $_"
    }
}

if (-not $SkipDownload) {
    # Download Odoo 18.0
    Write-Host "[7/10] Downloading Odoo 18.0..." -ForegroundColor Cyan
    if (-not (Test-Path "odoo-bin")) {
        Write-Host "Cloning Odoo 18.0 repository..." -ForegroundColor Yellow
        try {
            git clone --depth 1 --branch 18.0 https://github.com/odoo/odoo.git temp_odoo 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) {
                # Move files from temp_odoo to current directory
                Get-ChildItem -Path "temp_odoo" | Move-Item -Destination . -Force
                Remove-Item -Path "temp_odoo" -Recurse -Force
                Write-Host "✅ Odoo 18.0 downloaded successfully" -ForegroundColor Green
            } else {
                Write-Error "Failed to clone Odoo repository"
                exit 1
            }
        }
        catch {
            Write-Error "Error downloading Odoo: $_"
            exit 1
        }
    } else {
        Write-Host "✅ Odoo already downloaded" -ForegroundColor Green
    }
}

# Create Python virtual environment
Write-Host "[8/10] Creating Python virtual environment..." -ForegroundColor Cyan
if (-not (Test-Path "venv")) {
    try {
        python -m venv venv 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Virtual environment created successfully" -ForegroundColor Green
        } else {
            Write-Error "Failed to create virtual environment"
            exit 1
        }
    }
    catch {
        Write-Error "Error creating virtual environment: $_"
        exit 1
    }
} else {
    Write-Host "✅ Virtual environment already exists" -ForegroundColor Green
}

# Activate virtual environment and install dependencies
Write-Host "[9/10] Installing Python dependencies..." -ForegroundColor Cyan
$venvActivate = Join-Path $InstallDir "venv\Scripts\Activate.ps1"

if (Test-Path $venvActivate) {
    Write-Host "Activating virtual environment..." -ForegroundColor Yellow
    & $venvActivate
    
    Write-Host "Upgrading pip..." -ForegroundColor Yellow
    python -m pip install --upgrade pip 2>&1 | Out-Null
    
    # Install from requirements.txt if exists
    if (Test-Path "requirements.txt") {
        Write-Host "Installing requirements from requirements.txt..." -ForegroundColor Yellow
        pip install -r requirements.txt 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Some requirements failed to install, continuing with manual installation..."
        }
    }
    
    Write-Host "Installing critical dependencies..." -ForegroundColor Yellow
    $dependencies = @(
        "psycopg2-binary", "pillow", "reportlab", "qrcode[pil]", "python-dateutil",
        "decorator", "docutils", "feedparser", "geoip2", "greenlet", "jinja2",
        "lxml", "markupsafe", "num2words", "ofxparse", "passlib", "polib",
        "psutil", "python-stdnum", "pytz", "pyusb", "requests", "urllib3",
        "vobject", "werkzeug", "xlsxwriter", "zeep", "babel", "chardet",
        "cryptography", "idna", "libsass", "pyopenssl", "rjsmin"
    )
    
    foreach ($dep in $dependencies) {
        try {
            pip install $dep 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  ✅ $dep" -ForegroundColor Green
            } else {
                Write-Host "  ❌ $dep" -ForegroundColor Red
            }
        }
        catch {
            Write-Host "  ❌ $dep (Error: $_)" -ForegroundColor Red
        }
    }
    
    Write-Host "✅ Python dependencies installation completed" -ForegroundColor Green
} else {
    Write-Error "Could not find virtual environment activation script"
    exit 1
}

# Create configuration files
Write-Host "[10/10] Creating configuration files..." -ForegroundColor Cyan

# Create odoo.conf
$odooConf = @"
[options]
addons_path = addons
admin_passwd = admin
db_host = localhost
db_port = 5432
db_user = odoo
db_password = odoo
logfile = odoo.log
log_level = info
xmlrpc_port = 8069
longpolling_port = 8072
"@

$odooConf | Out-File -FilePath "odoo.conf" -Encoding UTF8
Write-Host "✅ Created odoo.conf" -ForegroundColor Green

# Create startup script
$startScript = @"
@echo off
cd /d "$InstallDir"
call venv\Scripts\activate.bat
python odoo-bin --config=odoo.conf
"@

$startScript | Out-File -FilePath "start_odoo.bat" -Encoding ASCII
Write-Host "✅ Created start_odoo.bat" -ForegroundColor Green

# Create verification script
$verifyScript = @'
Write-Host "Verifying Odoo 18.0 installation..." -ForegroundColor Green
Write-Host ""

Write-Host "Python version:" -ForegroundColor Yellow
python --version

Write-Host "PostgreSQL status:" -ForegroundColor Yellow
try {
    Get-Service postgresql* | Format-Table Name, Status, StartType
} catch {
    Write-Host "PostgreSQL service not found or not accessible" -ForegroundColor Red
}

Write-Host "Node.js version:" -ForegroundColor Yellow
if (Get-Command node -ErrorAction SilentlyContinue) {
    node --version
} else {
    Write-Host "Node.js not found" -ForegroundColor Red
}

Write-Host "SASS version:" -ForegroundColor Yellow
if (Get-Command sass -ErrorAction SilentlyContinue) {
    sass --version
} else {
    Write-Host "SASS not found" -ForegroundColor Red
}

Write-Host "Testing Python dependencies..." -ForegroundColor Yellow
try {
    & "venv\Scripts\python.exe" -c "import psycopg2, lxml; print('✅ Critical dependencies OK')"
} catch {
    Write-Host "❌ Some critical dependencies missing" -ForegroundColor Red
}

Write-Host ""
Write-Host "Installation verification completed!" -ForegroundColor Green
'@

$verifyScript | Out-File -FilePath "verify_installation.ps1" -Encoding UTF8
Write-Host "✅ Created verify_installation.ps1" -ForegroundColor Green

# Try to start PostgreSQL service
Write-Host "Attempting to start PostgreSQL service..." -ForegroundColor Yellow
try {
    $pgService = Get-Service postgresql* -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($pgService) {
        if ($pgService.Status -eq "Stopped") {
            Start-Service $pgService.Name
            Write-Host "✅ PostgreSQL service started" -ForegroundColor Green
        } else {
            Write-Host "✅ PostgreSQL service already running" -ForegroundColor Green
        }
    } else {
        Write-Warning "PostgreSQL service not found"
    }
}
catch {
    Write-Warning "Could not start PostgreSQL service: $_"
}

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "                    INSTALLATION COMPLETED!" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Configure PostgreSQL (create odoo user):" -ForegroundColor White
Write-Host "   - Connect: psql -U postgres" -ForegroundColor Gray
Write-Host "   - Run: CREATE USER odoo WITH CREATEDB PASSWORD 'odoo';" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Start Odoo:" -ForegroundColor White
Write-Host "   - Double-click: start_odoo.bat" -ForegroundColor Gray
Write-Host "   - Or run: python odoo-bin --config=odoo.conf" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Access web interface:" -ForegroundColor White
Write-Host "   - URL: http://localhost:8069" -ForegroundColor Gray
Write-Host "   - Create your first database" -ForegroundColor Gray
Write-Host ""
Write-Host "4. Verify installation:" -ForegroundColor White
Write-Host "   - Run: PowerShell -ExecutionPolicy Bypass -File verify_installation.ps1" -ForegroundColor Gray
Write-Host ""
Write-Host "Installation directory: $InstallDir" -ForegroundColor Cyan
Write-Host "Configuration file: $InstallDir\odoo.conf" -ForegroundColor Cyan
Write-Host "Startup script: $InstallDir\start_odoo.bat" -ForegroundColor Cyan
Write-Host ""
Write-Host "For support, check: INSTALACION_ODOO_18_WINDOWS.md" -ForegroundColor Yellow
Write-Host "================================================================" -ForegroundColor Cyan

Read-Host "Press Enter to exit"
