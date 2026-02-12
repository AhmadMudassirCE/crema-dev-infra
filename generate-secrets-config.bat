@echo off
REM Generate secrets configuration for terraform.tfvars from dev.env
REM Usage: generate-secrets-config.bat path\to\dev.env YOUR_AWS_ACCOUNT_ID us-east-1

setlocal enabledelayedexpansion

set ENV_FILE=%1
set ACCOUNT_ID=%2
set REGION=%3

if "%ENV_FILE%"=="" (
    echo Error: Please provide the path to dev.env file
    echo Usage: generate-secrets-config.bat path\to\dev.env YOUR_AWS_ACCOUNT_ID us-east-1
    exit /b 1
)

if "%ACCOUNT_ID%"=="" (
    echo Error: Please provide your AWS Account ID
    echo Usage: generate-secrets-config.bat path\to\dev.env YOUR_AWS_ACCOUNT_ID us-east-1
    exit /b 1
)

if "%REGION%"=="" (
    set REGION=us-east-1
)

echo # Copy this into your terraform.tfvars secrets section
echo.
echo secrets = [

for /f "usebackq tokens=1,* delims==" %%a in ("%ENV_FILE%") do (
    set KEY=%%a
    
    REM Skip DATABASE and REDIS related variables
    if not "!KEY!"=="DATABASE_URL" (
        if not "!KEY!"=="REDIS_URL" (
            if not "!KEY!"=="DATABASE_HOST" (
                if not "!KEY!"=="DATABASE_NAME" (
                    if not "!KEY!"=="DATABASE_PASSWORD" (
                        if not "!KEY!"=="DATABASE_PORT" (
                            if not "!KEY!"=="DATABASE_USERNAME" (
                                if not "!KEY!"=="HEROKU_POSTGRESQL_CHARCOAL_URL" (
                                    echo   {
                                    echo     name      = "!KEY!"
                                    echo     valueFrom = "arn:aws:ssm:%REGION%:%ACCOUNT_ID%:parameter/crema/!KEY!"
                                    echo   },
                                )
                            )
                        )
                    )
                )
            )
        )
    )
)

echo   # DATABASE_URL and REDIS_URL are automatically added by Terraform
echo ]

endlocal
