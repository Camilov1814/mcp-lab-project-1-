@echo off
REM Script de instalación para Windows
REM Laboratorio MCP

echo ==================================================
echo    Laboratorio MCP - Script de Instalacion
echo ==================================================
echo.

REM Colores en Windows (limitados)
set GREEN=[92m
set RED=[91m
set YELLOW=[93m
set NC=[0m

echo %GREEN%[INFO]%NC% Verificando requisitos...
echo.

REM Verificar Node.js
where node >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo %RED%[ERROR]%NC% Node.js no esta instalado.
    echo Por favor instala Node.js 18+ desde: https://nodejs.org/
    pause
    exit /b 1
)
echo %GREEN%[INFO]%NC% Node.js encontrado
node -v

REM Verificar Python
where python >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo %RED%[ERROR]%NC% Python no esta instalado.
    echo Por favor instala Python 3.11+ desde: https://www.python.org/
    echo O desde Microsoft Store: ms-windows-store://pdp/?productid=9NRWMJP3717K
    pause
    exit /b 1
)
echo %GREEN%[INFO]%NC% Python encontrado
python --version

REM Verificar PostgreSQL
where psql >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo %YELLOW%[WARN]%NC% psql no encontrado. Asegurate de tener PostgreSQL instalado.
) else (
    echo %GREEN%[INFO]%NC% PostgreSQL encontrado
    psql --version
)

echo.
echo %GREEN%[INFO]%NC% Todos los requisitos basicos satisfechos.
echo.

REM 1. Configurar MCP Ventas
echo ==================================================
echo %GREEN%[INFO]%NC% 1/4 Configurando MCP Ventas (Node.js)...
echo ==================================================

cd mcp-ventas-node

if not exist ".env" (
    echo %GREEN%[INFO]%NC% Creando archivo .env desde .env.example...
    copy .env.example .env
    echo %YELLOW%[WARN]%NC% Por favor edita mcp-ventas-node\.env con tus credenciales
)

echo %GREEN%[INFO]%NC% Instalando dependencias de Node.js...
call npm install

echo %GREEN%[INFO]%NC% Compilando TypeScript...
call npm run build

echo %GREEN%[INFO]%NC% MCP Ventas configurado
echo.

REM 2. Configurar MCP Pedidos
echo ==================================================
echo %GREEN%[INFO]%NC% 2/4 Configurando MCP Pedidos (Python)...
echo ==================================================

cd ..\mcp-pedidos-py

if not exist ".env" (
    echo %GREEN%[INFO]%NC% Creando archivo .env desde .env.example...
    copy .env.example .env
    echo %YELLOW%[WARN]%NC% Por favor edita mcp-pedidos-py\.env con tus credenciales
)

if not exist "venv" (
    echo %GREEN%[INFO]%NC% Creando entorno virtual de Python...
    python -m venv venv
)

echo %GREEN%[INFO]%NC% Activando entorno virtual e instalando dependencias...
call venv\Scripts\activate.bat
python -m pip install --upgrade pip
pip install -r requirements.txt
call deactivate

echo %GREEN%[INFO]%NC% MCP Pedidos configurado
echo.

REM 3. Configurar Gateway
echo ==================================================
echo %GREEN%[INFO]%NC% 3/4 Configurando MCP Gateway...
echo ==================================================

cd ..\mcp-gateway

echo %GREEN%[INFO]%NC% Instalando dependencias de Node.js...
call npm install

echo %GREEN%[INFO]%NC% Compilando TypeScript...
call npm run build

echo %GREEN%[INFO]%NC% MCP Gateway configurado
echo.

REM 4. Configurar Base de Datos
echo ==================================================
echo %GREEN%[INFO]%NC% 4/4 Configurando Base de Datos...
echo ==================================================

cd ..

set /p CARGAR_BD="Deseas cargar los datos de ejemplo en PostgreSQL ahora? (s/n): "
if /i "%CARGAR_BD%"=="s" (
    set /p PG_USER="Usuario de PostgreSQL (default: postgres): "
    if "%PG_USER%"=="" set PG_USER=postgres
    
    set /p PG_DB="Base de datos (default: mcp_lab): "
    if "%PG_DB%"=="" set PG_DB=mcp_lab
    
    echo %GREEN%[INFO]%NC% Ejecutando script SQL...
    psql -U %PG_USER% -d %PG_DB% -f sql\setup_database.sql
    
    if %ERRORLEVEL% EQU 0 (
        echo %GREEN%[INFO]%NC% Base de datos configurada exitosamente
    ) else (
        echo %RED%[ERROR]%NC% Error al cargar datos. Puedes ejecutar manualmente:
        echo   psql -U %PG_USER% -d %PG_DB% -f sql\setup_database.sql
    )
) else (
    echo %GREEN%[INFO]%NC% Omitiendo configuracion de base de datos.
    echo %YELLOW%[WARN]%NC% Recuerda ejecutar sql\setup_database.sql manualmente:
    echo   psql -U postgres -d mcp_lab -f sql\setup_database.sql
)

echo.
echo ==================================================
echo %GREEN%[INFO]%NC% Instalacion Completada!
echo ==================================================
echo.
echo Proximos pasos:
echo.
echo 1. Edita los archivos .env con tus credenciales de PostgreSQL:
echo    - mcp-ventas-node\.env
echo    - mcp-pedidos-py\.env
echo.
echo 2. Si no lo hiciste, carga los datos de ejemplo:
echo    psql -U postgres -d mcp_lab -f sql\setup_database.sql
echo.
echo 3. Configura Claude Desktop:
echo    - Abre Settings - Developer - Edit Config
echo    - Agrega la configuracion del gateway (ver README.md)
echo.
echo 4. Inicia el gateway:
echo    cd mcp-gateway
echo    npm start
echo.
echo Para mas informacion, consulta README.md
echo.
pause
