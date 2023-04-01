# Sitecore Solr Module
Terraform Module for setting up Solr on Azure VM for Sitecore. 

This Terraform module takes care of complete automation for Solr Setup for Sitecore by:
  - Creating a Public IP assigned Azure Windows VM
  - Installing Solr
  - Create Sitecore Cores
  - Create xConnect(xDB) Cores
  - Firewall updates for Solr to be accessed externally