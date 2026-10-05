# Guardianship App — Direct Backend Deploy Script
# Deploys backend to 109.199.99.156 without GitHub Actions

param(
    [string]$Password
)

if (-not $Password) {
    $Password = Read-Host -Prompt "Enter root password for 109.199.99.156" -AsSecureString
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
    $Password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
}

python "$PSScriptRoot\.github\scripts\deploy.py" $Password
