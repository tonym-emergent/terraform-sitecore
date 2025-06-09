# This script installs and configures Solr and Zookeeper for Sitecore development.

# Set parameter for Sitecore version
param(
    [string]$sitecoreVersion = "10.4.0"
)
$sitecoreVersion = "10.4.0"
# Set Execution Policies
Set-ExecutionPolicy AllSigned
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072

# Install Chocolatey
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

# Create Directories
$createDirectories = @(
    'C:\solr',
    'C:\installs',
    'C:\solr\zookeeper_data'
)
foreach ($path in $createDirectories) {
    $validatePath = Test-Path -Path $path
    if ($validatePath -eq $False) {
        mkdir $path
    } else {
        Write-Host "Path $path already exists"
    }
}

# Install Java
choco feature enable -n allowGlobalConfirmation
choco install jre8 -y
refreshenv
setx JAVA_HOME -m "C:\Program Files\Java\jre1.8.0_451"
setx PATH "%PATH%;%JAVA_HOME%\bin"
refreshenv
Write-Output $env:JAVA_HOME

# Install NSSM, 7Zip, Notepad++
choco install nssm 7zip notepadplusplus telnet -y

