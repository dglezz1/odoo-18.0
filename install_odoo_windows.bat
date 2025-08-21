@echo off
REM Odoo 18.0 Automated Installation Script for Windows
REM Created: August 21, 2025
REM Based on successful macOS installation

echo.
echo ================================================================
echo            ODOO 18.0 WINDOWS INSTALLATION SCRIPT
echo ================================================================
echo.
echo This script will install and configure Odoo 18.0 on Windows
echo Prerequisites: Administrator rights and internet connection
echo.
pause

REM Check if running as Administrator
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: This script requires Administrator privileges
    echo Please run PowerShell as Administrator and try again
    pause
    exit /b 1
)

echo [1/10] Checking system requirements...

REM Set installation directory
set ODOO_DIR=C:\odoo-18.0
set PYTHON_VERSION=3.11
set POSTGRESQL_VERSION=14

echo Installation directory: %ODOO_DIR%

REM Create installation directory
if not exist "%ODOO_DIR%" (
    mkdir "%ODOO_DIR%"
    echo Created directory: %ODOO_DIR%
) else (
    echo Directory already exists: %ODOO_DIR%
)

cd /d "%ODOO_DIR%"

echo [2/10] Installing Python 3.11...
REM Check if Python is already installed
python --version >nul 2>&1
if %errorLevel% neq 0 (
    echo Installing Python 3.11 via winget...
    winget install Python.Python.3.11 --silent --accept-source-agreements --accept-package-agreements
    if %errorLevel% neq 0 (
        echo ERROR: Failed to install Python
        echo Please install Python 3.11 manually from python.org
        pause
        exit /b 1
    )
    echo Python installed successfully
) else (
    echo Python already installed
    python --version
)

REM Refresh environment variables
call refreshenv.cmd >nul 2>&1

echo [3/10] Installing Git...
REM Check if Git is installed
git --version >nul 2>&1
if %errorLevel% neq 0 (
    echo Installing Git via winget...
    winget install Git.Git --silent --accept-source-agreements --accept-package-agreements
    if %errorLevel% neq 0 (
        echo ERROR: Failed to install Git
        echo Please install Git manually from git-scm.com
        pause
        exit /b 1
    )
    echo Git installed successfully
) else (
    echo Git already installed
    git --version
)

echo [4/10] Installing PostgreSQL...
REM Check if PostgreSQL is installed
psql --version >nul 2>&1
if %errorLevel% neq 0 (
    echo Installing PostgreSQL 14 via winget...
    winget install PostgreSQL.PostgreSQL.14 --silent --accept-source-agreements --accept-package-agreements
    if %errorLevel% neq 0 (
        echo WARNING: Failed to install PostgreSQL via winget
        echo Please install PostgreSQL 14 manually from postgresql.org
        echo Set password for postgres user to 'postgres'
        pause
    ) else (
        echo PostgreSQL installed successfully
    )
) else (
    echo PostgreSQL already installed
    psql --version
)

echo [5/10] Installing Visual Studio Build Tools...
REM Check if build tools are available
cl >nul 2>&1
if %errorLevel% neq 0 (
    echo Installing Microsoft C++ Build Tools...
    winget install Microsoft.VisualStudio.2022.BuildTools --silent --accept-source-agreements --accept-package-agreements
    if %errorLevel% neq 0 (
        echo WARNING: Failed to install Build Tools via winget
        echo Please install Visual Studio Build Tools manually
        echo Download from: https://visualstudio.microsoft.com/visual-cpp-build-tools/
    ) else (
        echo Build Tools installed successfully
    )
) else (
    echo Build Tools already available
)

echo [6/10] Installing Node.js and SASS...
REM Check if Node.js is installed
node --version >nul 2>&1
if %errorLevel% neq 0 (
    echo Installing Node.js via winget...
    winget install OpenJS.NodeJS --silent --accept-source-agreements --accept-package-agreements
    if %errorLevel% neq 0 (
        echo ERROR: Failed to install Node.js
        echo Please install Node.js manually from nodejs.org
        pause
        exit /b 1
    )
    echo Node.js installed successfully
) else (
    echo Node.js already installed
    node --version
)

REM Install SASS globally
echo Installing SASS globally...
call npm install -g sass
if %errorLevel% neq 0 (
    echo WARNING: Failed to install SASS globally
    echo You may need to install it manually: npm install -g sass
)

echo [7/10] Downloading Odoo 18.0...
if not exist "odoo-bin" (
    echo Cloning Odoo 18.0 repository...
    git clone --depth 1 --branch 18.0 https://github.com/odoo/odoo.git temp_odoo
    if %errorLevel% neq 0 (
        echo ERROR: Failed to clone Odoo repository
        pause
        exit /b 1
    )
    
    REM Move files from temp_odoo to current directory
    xcopy temp_odoo\* . /E /I /Y >nul
    rmdir /S /Q temp_odoo
    echo Odoo 18.0 downloaded successfully
) else (
    echo Odoo already downloaded
)

echo [8/10] Creating Python virtual environment...
if not exist "venv" (
    echo Creating virtual environment...
    python -m venv venv
    if %errorLevel% neq 0 (
        echo ERROR: Failed to create virtual environment
        pause
        exit /b 1
    )
    echo Virtual environment created successfully
) else (
    echo Virtual environment already exists
)

REM Activate virtual environment
echo Activating virtual environment...
call venv\Scripts\activate.bat

echo [9/10] Installing Python dependencies...
echo Upgrading pip...
python -m pip install --upgrade pip

echo Installing requirements from requirements.txt...
pip install -r requirements.txt
if %errorLevel% neq 0 (
    echo WARNING: Some requirements failed to install
    echo Continuing with manual dependency installation...
)

echo Installing critical dependencies...
pip install psycopg2-binary pillow reportlab qrcode[pil] python-dateutil decorator docutils
pip install feedparser geoip2 greenlet jinja2 lxml markupsafe num2words ofxparse
pip install passlib polib psutil python-stdnum pytz pyusb requests urllib3 vobject
pip install werkzeug xlsxwriter zeep babel chardet cryptography idna libsass
pip install pyopenssl rjsmin

echo [10/10] Creating configuration files...

REM Create odoo.conf
echo Creating odoo.conf...
(
echo [options]
echo addons_path = addons
echo admin_passwd = admin
echo db_host = localhost
echo db_port = 5432
echo db_user = odoo
echo db_password = odoo
echo logfile = odoo.log
echo log_level = info
echo xmlrpc_port = 8069
echo longpolling_port = 8072
) > odoo.conf

REM Create startup script
echo Creating start_odoo.bat...
(
echo @echo off
echo cd /d "%ODOO_DIR%"
echo call venv\Scripts\activate.bat
echo python odoo-bin --config=odoo.conf
) > start_odoo.bat

REM Create verification script
echo Creating verify_installation.ps1...
(
echo Write-Host "Verifying Odoo 18.0 installation..." -ForegroundColor Green
echo Write-Host "Python version:" -ForegroundColor Yellow
echo python --version
echo Write-Host "PostgreSQL status:" -ForegroundColor Yellow
echo Get-Service postgresql*
echo Write-Host "Node.js version:" -ForegroundColor Yellow  
echo node --version
echo Write-Host "SASS version:" -ForegroundColor Yellow
echo sass --version
echo Write-Host "Testing Python dependencies..." -ForegroundColor Yellow
echo python -c "import psycopg2, lxml; print('✅ Critical dependencies OK')"
echo Write-Host "Installation verification completed!" -ForegroundColor Green
) > verify_installation.ps1

echo.
echo ================================================================
echo                    INSTALLATION COMPLETED!
echo ================================================================
echo.
echo Next steps:
echo 1. Configure PostgreSQL (create odoo user):
echo    - Connect: psql -U postgres
echo    - Run: CREATE USER odoo WITH CREATEDB PASSWORD 'odoo';
echo.
echo 2. Start Odoo:
echo    - Double-click: start_odoo.bat
echo    - Or run: python odoo-bin --config=odoo.conf
echo.
echo 3. Access web interface:
echo    - URL: http://localhost:8069
echo    - Create your first database
echo.
echo 4. Verify installation:
echo    - Run: PowerShell -ExecutionPolicy Bypass -File verify_installation.ps1
echo.
echo Installation directory: %ODOO_DIR%
echo Configuration file: %ODOO_DIR%\odoo.conf
echo Startup script: %ODOO_DIR%\start_odoo.bat
echo.
echo For support, check: INSTALACION_ODOO_18_WINDOWS.md
echo ================================================================
echo.
pause

REM Try to start PostgreSQL service if it exists
echo Attempting to start PostgreSQL service...
net start postgresql* >nul 2>&1

echo Installation script completed!
echo You can now run start_odoo.bat to launch Odoo
pause
