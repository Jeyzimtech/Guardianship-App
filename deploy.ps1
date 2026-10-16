# Guardianship App — Direct Backend Deploy Script
# Deploys backend to 109.199.99.156 without GitHub Actions

param(
    [string]$Password
)

if ($Password) {
    throw "Do not pass the VPS password in a command or script argument. Run .\deploy.ps1 without parameters to enter it securely."
}

python "$PSScriptRoot\.github\scripts\deploy.py"
