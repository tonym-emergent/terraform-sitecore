# Set parameter for Sitecore version
param(
    [string]$sitecoreVersion = "10.4.0"
)

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


### ZOOKEEPER INSTALLATION ###
# Set Zookeeper version
$zookeeperVersion = "3.8.4"

# Download Zookeeper latest stable release ($zookeeperVersion)
Invoke-WebRequest -Uri "https://downloads.apache.org/zookeeper/zookeeper-$zookeeperVersion/apache-zookeeper-$zookeeperVersion-bin.tar.gz" -OutFile "C:\solr\apache-zookeeper-$zookeeperVersion-bin.tar.gz"
# Extract to C:\solr
tar -xvf "C:\solr\apache-zookeeper-$zookeeperVersion-bin.tar.gz" -C "C:\solr"

# Create zoo.cfg file
$zooCfgContent = @"
tickTime=2000
initLimit=10
syncLimit=5
dataDir=C://solr//zookeeper_data
clientPort=2181
server.1=10.0.2.4:2888:3888
"@
$zooCfgPath = "C:\solr\apache-zookeeper-$($zookeeperVersion)-bin\conf\zoo.cfg"
$zooCfgContent | Out-File -FilePath $zooCfgPath -Encoding ASCII


# Set Zookeeper path
setx ZOOKEEPER_HOME -m C:\solr\zookeeper-$zookeeperVersion-bin
setx PATH "%PATH%;%ZOOKEEPER_HOME%\bin"

# Start Zookeeper
Start-Process -FilePath "C:\solr\apache-zookeeper-$($zookeeperVersion)-bin\bin\zkServer.cmd" -NoNewWindow

# Validate Zookeeper in new cmd window
Start-Process -FilePath "cmd.exe" -ArgumentList "/c C:\solr\apache-zookeeper-$($zookeeperVersion)-bin\bin\zkCli.cmd" -NoNewWindow

# Set Zookeeper server ID
New-Item -Path C:\solr\zookeeper_data -Name myid -ItemType file -Value 1

# Install Zookeeper as a service using NSSM
nssm install zookeeper C:\solr\apache-zookeeper-$zookeeperVersion-bin\bin\zkServer.cmd
nssm set zookeeper AppDirectory C:\solr\apache-zookeeper-$zookeeperVersion-bin\bin\


### SOLR INSTALLATION ###
$solrVersion = "8.11.2"
Install-PackageProvider -Name NuGet -Force

# Register the Sitecore Gallery repository
Register-PSRepository -Name SitecoreGallery -SourceLocation https://nuget.sitecore.com/resources/v2/


# Install latest Sitecore Installation Framework
Install-Module -Name SitecoreInstallFramework -Repository SitecoreGallery -Force

# Get Solr jsons
$artifactsUrl = "https://raw.githubusercontent.com/tonym-emergent/terraform-sitecore/main/Artifacts/$($sitecoreVersion).zip"
$destinationPath = "C:\installs\$($sitecoreVersion).zip"
Invoke-WebRequest -Uri $artifactsUrl -OutFile $destinationPath
# Extract the zip file
Expand-Archive -Path $destinationPath -DestinationPath "C:\installs" -Force

<#
# Install Solr
## TODO: Update the Solr path and Zookeeper path as per your environment
Install-SitecoreConfiguration -Path "c:\installs\$($sitecoreVersion)\Solr-SingleDeveloper.json"
Install-SitecoreConfiguration -Path "c:\installs\$($sitecoreVersion)\sitecore-solr.json"
Install-SitecoreConfiguration -Path "c:\installs\$($sitecoreVersion)\xconnect-solr.json"

# Start Solr
Start-Process -FilePath "C:\solr\solr-$($solrVersion)\bin\solr.cmd" -ArgumentList "start -c -f -p 8983 -z 10.0.2.4:2181" -NoNewWindow

# Validate UI comes up
Start-Process -FilePath "cmd.exe" -ArgumentList "/c start http://localhost:8983/solr/#/~cloud" -NoNewWindow

# Install Solr as a service using NSSM
nssm install solr C:\solr\solr-$($solrVersion)\bin\solr.cmd
nssm set solr AppDirectory C:\solr\solr-$($solrVersion)\bin\

# Update Solr Default Config
$from = "C:\solr\solr-$($solrVersion)\server\solr\configsets\_default*"
$to = "C:\solr\solr-$($solrVersion)\server\solr\configsets\sitecore_configs"

Get-ChildItem -Path $from | % {
    Copy-Item $_.fullname $to -Recurse -Force
}
#>