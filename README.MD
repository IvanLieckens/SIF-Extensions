# Sitecore SIF Extensions
A small project for SIF Extensions I created to install client's environments using SIF

# Tasks
## ManageSolrCloudCollection
Similar to ManageSolrCore from SIF but altered to talk to the Collections endpoint of SolrCloud to enable executing actions against it. https://lucene.apache.org/solr/guide/8_1/collections-api.html

### Example JSON
```json
{
    "Tasks": {
        "CreateCollections":{
			"Description" : "Tells SolrCloud to create the new collections.",
            "Type": "ManageSolrCloudCollection",
            "Params": [
                { "Action": "Create", "Address": "[parameter('SolrCloudUrl')]", "Arguments": { "name": "[variable('Core.Name')]", "numShards": "[parameter('NumberOfShards')]", "collection.configName": "[parameter('SolrCloudConfigName')]", "property.update.autoCreateFields": "false" } },
                { "Action": "Create", "Address": "[parameter('SolrCloudUrl')]", "Arguments": { "name": "[variable('Master.Name')]", "numShards": "[parameter('NumberOfShards')]", "collection.configName": "[parameter('SolrCloudConfigName')]", "property.update.autoCreateFields": "false" } },
                { "Action": "Create", "Address": "[parameter('SolrCloudUrl')]", "Arguments": { "name": "[variable('Web.Name')]", "numShards": "[parameter('NumberOfShards')]", "collection.configName": "[parameter('SolrCloudConfigName')]", "property.update.autoCreateFields": "false" } }
            ]
        }
    }
}
```

## ManageSolrCloudConfiguration
Standard SIF will move and modify configuration on disk but this doesn't work for a SolrCloud. This task can talk to the ConfigSets API https://lucene.apache.org/solr/guide/8_1/configsets-api.html to handle introducing the right configuration for Sitecore Solr Indexes.

**Special note: Ensure that you ZIP using 7-zip or similar tools to create a configset to upload, packages created by PowerShell or Windows will fail**

### Example JSON
```json
{
    "Tasks": {
        "UploadConfig":{
            "Description" : "Uploads the configuration to SolrCloud if it doesn't exist yet.",
            "Type": "ManageSolrCloudConfiguration",
            "Params": [
                { "Action": "upload", "Address": "[parameter('SolrCloudUrl')]", "Arguments": { "name": "[parameter('SolrCloudConfigName')]" }, "ConfigZipPath": "[parameter('SolrCloudConfigZipPath')]" }
            ]
        },
    }
}
```

## SitecoreUrlFixed
There is a bug in the SitecoreUrl SIF Task that will cause the authentication part to fail because it includes a parameter that will trigger the password reset instead of logging in. This task fixes this. (Was required for https://gist.github.com/IvanLieckens/c5d99be61404ca5cbc3c2bcf5b5da379)

### Example JSON
```json
{
    "Tasks": {
        "ImportLanguagePack": {
            "Description": "Import the language pack.",
            "Type": "SitecoreUrlFixed",
            "Params": {
                "SitecoreInstanceRoot": "[concat('https://', parameter('DnsName'))]",
                "SitecoreActionPath": "[concat('sitecore/admin/ImportLanguage.aspx?db=', parameter('Database'), '&file=', variable('File.QueryString'), '&lang=', parameter('Languages'))]",
                "UserName": "admin",
                "Password": "[parameter('SitecoreAdminPassword')]"
            },
            "Skip": "[or(not(parameter('File')), not(parameter('AdminPage')))]"
        }
    }
}
```