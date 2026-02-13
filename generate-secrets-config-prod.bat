@echo off
REM Generate secrets configuration for terraform.tfvars from prod.env
REM Uses /crema-prod/ SSM prefix to separate from dev (/crema/)
REM Usage: generate-secrets-config-prod.bat path\to\prod.env YOUR_AWS_ACCOUNT_ID us-east-1

setlocal enabledelayedexpansion

set ENV_FILE=%1
set ACCOUNT_ID=%2
set REGION=%3

if "%ENV_FILE%"=="" (
    echo Error: Please provide the path to prod.env file
    echo Usage: generate-secrets-config-prod.bat path\to\prod.env YOUR_AWS_ACCOUNT_ID us-east-1
    exit /b 1
)

if "%ACCOUNT_ID%"=="" (
    echo Error: Please provide your AWS Account ID
    echo Usage: generate-secrets-config-prod.bat path\to\prod.env YOUR_AWS_ACCOUNT_ID us-east-1
    exit /b 1
)

if "%REGION%"=="" (
    set REGION=us-east-1
)

echo # Copy this into your terraform.tfvars secrets section
echo # Production secrets using /crema-prod/ SSM prefix
echo.
echo secrets = [

for /f "usebackq tokens=1,* delims==" %%a in ("%ENV_FILE%") do (
    set KEY=%%a

    REM Skip DATABASE_URL, REDIS_URL, and HEROKU_POSTGRESQL_CHARCOAL_URL only
    if "!KEY!"=="DATABASE_URL" (
        REM skip - Terraform creates this
    ) else if "!KEY!"=="REDIS_URL" (
        REM skip - Terraform creates this
    ) else if "!KEY!"=="HEROKU_POSTGRESQL_CHARCOAL_URL" (
        REM skip - Heroku legacy
    ) else (
        echo   {
        echo     name      = "!KEY!"
        echo     valueFrom = "arn:aws:ssm:%REGION%:%ACCOUNT_ID%:parameter/crema-prod/!KEY!"
        echo   },
    )
)

echo   # DATABASE_URL and REDIS_URL are automatically added by Terraform
echo ]

endlocal
