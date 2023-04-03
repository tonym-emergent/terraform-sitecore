
param(
    [Parameter(Mandatory)]
    [string]$SitecoreVersion
)

# Add Web-Server Feature
Add-WindowsFeature Web-Server

# Open Firewall for Port 8983
New-NetFirewallRule -DisplayName "Whitelist Solr Port" -Direction inboud -Profile Any -LocalPort 8983 -Protocol TCP

$ArtifactsUrl = "https://github.com/codeblitzmaster/terraform-azurerm-sitecoresolr/blob/main/Artifacts/$($SitecoreVersion).zip"

$CWD= Get-Location
$File = $(Split-Path -Path $ArtifactsUrl -Leaf)

Write-Host $File $CWD

$FileDownloadLocation = "$($CWD)\artifact.zip"

Write-Host $FileDownloadLocation

$ExtractionLocation = "$(CWD)\"

Invoke-WebRequest -Uri $ArtifactsUrl -OutFile $FileDownloadLocation

Expand-Archive -LiteralPath $FileDownloadLocation -DestinationPath $ExtractionLocation