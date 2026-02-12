@echo off
REM Batch script to load environment variables from dev.env into SSM Parameter Store
REM Usage: load-env-to-ssm.bat path\to\dev.env us-east-1

setlocal enabledelayedexpansion

set ENV_FILE=%1
set REGION=%2
set APP_NAME=crema

if "%ENV_FILE%"=="" (
    echo Error: Please provide the path to dev.env file
    echo Usage: load-env-to-ssm.bat path\to\dev.env us-east-1
    exit /b 1
)

if "%REGION%"=="" (
    set REGION=us-east-1
)

echo ==^> Loading environment variables from %ENV_FILE% to SSM Parameter Store
echo     Region: %REGION%
echo     Prefix: /%APP_NAME%/
echo.

set SUCCESS_COUNT=0
set SKIP_COUNT=0

for /f "usebackq tokens=1,* delims==" %%a in ("%ENV_FILE%") do (
    set KEY=%%a
    set VALUE=%%b
    
    REM Skip DATABASE and REDIS related variables (Terraform creates these)
    if "!KEY!"=="DATABASE_URL" (
        echo [SKIP] !KEY! - will be created by Terraform
        set /a SKIP_COUNT+=1
    ) else if "!KEY!"=="REDIS_URL" (
        echo [SKIP] !KEY! - will be created by Terraform
        set /a SKIP_COUNT+=1
    ) else if "!KEY!"=="DATABASE_HOST" (
        echo [SKIP] !KEY! - will be created by Terraform
        set /a SKIP_COUNT+=1
    ) else if "!KEY!"=="DATABASE_NAME" (
        echo [SKIP] !KEY! - will be created by Terraform
        set /a SKIP_COUNT+=1
    ) else if "!KEY!"=="DATABASE_PASSWORD" (
        echo [SKIP] !KEY! - will be created by Terraform
        set /a SKIP_COUNT+=1
    ) else if "!KEY!"=="DATABASE_PORT" (
        echo [SKIP] !KEY! - will be created by Terraform
        set /a SKIP_COUNT+=1
    ) else if "!KEY!"=="DATABASE_USERNAME" (
        echo [SKIP] !KEY! - will be created by Terraform
        set /a SKIP_COUNT+=1
    ) else if "!KEY!"=="HEROKU_POSTGRESQL_CHARCOAL_URL" (
        echo [SKIP] !KEY! - will be created by Terraform
        set /a SKIP_COUNT+=1
    ) else (
        REM Create parameter in SSM
        aws ssm put-parameter --region %REGION% --name "/%APP_NAME%/!KEY!" --value "!VALUE!" --type String --description "Environment variable from dev.env" --overwrite >nul 2>&1
        if !errorlevel! equ 0 (
            echo [OK] Created /%APP_NAME%/!KEY!
            set /a SUCCESS_COUNT+=1
        ) else (
            echo [ERROR] Failed to create /%APP_NAME%/!KEY!
        )
    )
)

echo.
echo ==^> Summary:
echo     Created: %SUCCESS_COUNT% parameters
echo     Skipped: %SKIP_COUNT% parameters (Terraform will create)
echo.
echo Note: DATABASE_URL and REDIS_URL will be automatically created by Terraform
echo       when you deploy the RDS and Redis modules.
echo.
echo To view all parameters:
echo   aws ssm get-parameters-by-path --path /%APP_NAME% --region %REGION%
echo.

endlocal
