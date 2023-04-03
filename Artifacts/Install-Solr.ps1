 
param(
    [Parameter(Mandatory)]
    [string]$SitecoreVersion = "10.3.0"
)

# Add Web-Server Feature
Add-WindowsFeature Web-Server

# Open Firewall for Port 8983
New-NetFirewallRule -DisplayName "Whitelist Solr Port" -Direction inbound -Profile Any -LocalPort 8983 -Protocol TCP

$ArtifactsUrl = "https://raw.githubusercontent.com/codeblitzmaster/terraform-azurerm-sitecoresolr/main/Artifacts/$($SitecoreVersion).zip"

$CWD= Get-Location
$File = $(Split-Path -Path $ArtifactsUrl -Leaf)

Write-Host $File $CWD

$FileDownloadLocation = "$($CWD)\artifact.zip"

Write-Host $FileDownloadLocation

$ExtractionLocation = "$($CWD)\"

Invoke-WebRequest -Uri $ArtifactsUrl -OutFile $FileDownloadLocation

Expand-Archive -LiteralPath $FileDownloadLocation -DestinationPath $ExtractionLocation -Force

# Set unrestricted execution to current user
Set-ExecutionPolicy -Scope CurrentUser Unrestricted

# Install Dependency for PSRepo Sitecore
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force

CD "$($SitecoreVersion)"

# Register Repository
Register-PSRepository -Name SitecoreGallery https://sitecore.myget.org/F/sc-powershell/api/v2

# List all versions
# Find-Module -Name SitecoreInstallFramework -AllVersions

Write-Host "SIF Installation Starts"
# Instal the latest version
Install-Module -Name SitecoreInstallFramework -Repository SitecoreGallery -Force
Write-Host "SIF Installation Ends"

# Install a specific version
# Install-Module -Name SitecoreInstallFramework -Repository SitecoreGallery -RequiredVersion 1.2.1

# Verify multiple versions have been installed
# Get-InstalledModule -Name SitecoreInstallFramework -AllVersions

Write-Host "Install Solr Starts"
Install-SitecoreConfiguration -Path ".\Solr-SingleDeveloper.json"
Write-Host "Install Solr Ends"

Write-Host "Create Sitecore Solr Cores Starts"
$scSolrParams = @{
    Path = ".\sitecore-solr.json"
}

Install-SitecoreConfiguration @scSolrParams
Write-Host "Create Sitecore Solr Cores Ends"


Write-Host "Create xDB Solr Cores Starts"
$xdbSolrParams = @{
    Path = ".\xconnect-solr.json"
}

Install-SitecoreConfiguration @xdbSolrParams
Write-Host "Create xDB Solr Cores Ends" 
