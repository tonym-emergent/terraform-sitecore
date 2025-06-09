# Post Deployment Configuration
# This script is intended to be run after the initial deployment of the VM on Azure and after the installation of chocolatey, Java, and NSSM.
# It performs additional configurations such as updating Solr's default configuration, setting up security, and configuring firewall rules.



### ZOOKEEPER INSTALLATION ###
# Set Zookeeper version
$zookeeperVersion = "3.8.4"
$zookeeperIPAddress = "10.0.2.4"

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
server.1=$($zookeeperIPAddress):2888:3888
"@
$zooCfgPath = "C:\solr\apache-zookeeper-$($zookeeperVersion)-bin\conf\zoo.cfg"
$zooCfgContent | Out-File -FilePath $zooCfgPath -Encoding ASCII


# Set Zookeeper path
setx ZOOKEEPER_HOME -m C:\solr\zookeeper-$zookeeperVersion-bin
setx PATH "%PATH%;%ZOOKEEPER_HOME%\bin"


# Set Zookeeper server ID
New-Item -Path C:\solr\zookeeper_data -Name myid -ItemType file -Value 1

# Install Zookeeper as a service using NSSM
nssm install zookeeper C:\solr\apache-zookeeper-$zookeeperVersion-bin\bin\zkServer.cmd
nssm set zookeeper AppDirectory C:\solr\apache-zookeeper-$zookeeperVersion-bin\bin\
nssm start zookeeper



### SOLR INSTALLATION ###
$solrVersion = "8.11.2"

Install-PackageProvider -Name NuGet -Force

# Register the Sitecore Gallery repository
Register-PSRepository -Name SitecoreGallery -SourceLocation https://nuget.sitecore.com/resources/v2/

# Install latest Sitecore Installation Framework
Install-Module -Name SitecoreInstallFramework -Repository SitecoreGallery -Force

# Get Solr jsons (Currently forked to TonyM's repository)
$artifactsUrl = "https://raw.githubusercontent.com/tonym-emergent/terraform-sitecore/main/Artifacts/$($sitecoreVersion).zip"
$destinationPath = "C:\installs\$($sitecoreVersion).zip"
Invoke-WebRequest -Uri $artifactsUrl -OutFile $destinationPath
# Extract the zip file
Expand-Archive -Path $destinationPath -DestinationPath "C:\installs" -Force
# Install Solr
## TODO: Update the Solr path and Zookeeper path as per your environment
Install-SitecoreConfiguration -Path "c:\installs\$($sitecoreVersion)\Solr-SingleDeveloper.json"


# Install Solr as a service using NSSM
nssm install "solr" C:\solr\solr-$($solrVersion)\bin\solr.cmd
nssm set "solr" AppDirectory C:\solr\solr-$($solrVersion)\bin\
nssm set "solr" AppParameters "start -c -f -p 8983 -z $($zookeeperIPAddress):2181"
nssm start "solr"

# Update Solr Default Config
$from = "C:\solr\solr-$($solrVersion)\server\solr\configsets\_default*"
$to = "C:\solr\solr-$($solrVersion)\server\solr\configsets\sitecore_configs"

Get-ChildItem -Path $from | % {
    Copy-Item $_.fullname $to -Recurse -Force
}


### SOLR CONFIGURATION ###
# Set path variables
$schemaPath = "C:\solr\solr-$($solrVersion)\server\solr\configsets\sitecore_configs\conf\managed-schema"

# Update uniqueKey in managed-schema
[xml]$schema = Get-Content $schemaPath
$schema.schema.uniqueKey = "_uniqueid"

# Add _uniqueid field if not already present
$fields = $schema.schema.field
if (-not ($fields | Where-Object { $_.name -eq "_uniqueid" })) {
    $newField = $schema.CreateElement("field")
    $newField.SetAttribute("name", "_uniqueid")
    $newField.SetAttribute("type", "string")
    $newField.SetAttribute("indexed", "true")
    $newField.SetAttribute("required", "true")
    $newField.SetAttribute("stored", "true")
    $schema.schema.AppendChild($newField) | Out-Null
}

# Save changes
$schema.Save($schemaPath)

# Upload configset to Zookeeper
cd "C:\solr\solr-$($solrVersion)\bin"
& .\solr.cmd zk upconfig -d ..\server\solr\configsets\sitecore_configs -n sitecore -z $($zookeeperIPAddress):2181

# Define collections
$collections = @(
    "raymond_master_index", "raymond_web_index", "sitecore_analytics_index", "sitecore_core_index",
    "sitecore_fxm_master_index", "sitecore_fxm_web_index", "sitecore_list_index",
    "sitecore_marketing_asset_index_master", "sitecore_marketing_asset_index_web",
    "sitecore_marketingdefinitions_master", "sitecore_marketingdefinitions_web",
    "sitecore_master_index", "sitecore_personalization_index", "sitecore_suggested_test_index",
    "sitecore_sxa_master_index", "sitecore_sxa_web_index", "sitecore_testing_index",
    "sitecore_web_index", "social_messages_master", "social_messages_web", "xdb", "xdb_rebuild"
)

$rebuildCollections = $collections | ForEach-Object { "${_}_rebuild" }
$collections += $rebuildCollections

# Create collections
foreach ($col in $collections) {
    $colName = $col
    $collectionParam = @("create_collection", "-c", $colName, "-n", "sitecore", "-s", "1", "-rf", "2")
    if ($colName -eq "xdb_rebuild_rebuild") {
        $collectionParam = @("create_collection", "-c", $colName, "-n", "sitecore_xdb", "-s", "1", "-rf", "2")
    }
    #& .\solr.cmd @collectionParam
    Write-Output "& .\solr.cmd $collectionParam"
}

# Disable autoCreateFields for all collections
foreach ($col in $collections) {
    & .\solr.cmd config -c $col -p 8983 -action set-user-property -property update.autoCreateFields -value false
}

# Restart services
Restart-Service solr -Force
Restart-Service zookeeper -Force



## SECURITY CONFIGURATION ##

# Add security.json to ZooKeeper
$securityJsonPath = "C:\installs\security.json"
& .\solr.cmd zk cp file:$securityJsonPath zk:/security.json -z "$($zookeeperIPAddress):2181"

# Final Configurations
# Frewall Rules
New-NetFirewallRule -RemoteAddress 192.168.237.0/24 -DisplayName 'Raymond Trusted Subnet' -Direction inbound -Profile Any -Action Allow
New-NetFirewallRule -RemoteAddress 168.63.129.16 -DisplayName 'Raymond Azure Load Balancer Health Check' -Direction inbound -Profile Any -Action Allow
