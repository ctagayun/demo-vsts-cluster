param(
   [string] [Parameter(Mandatory = $true)] $Name,
   [string] $TemplateName = "onenode.loadbalancer.json",  # name of the cluster ARM template
   [string] $Location = "westeurope",        # Physical location of all the resources
   [string] [Parameter(Mandatory = $true)] $TenantId,
   [string] [Parameter(Mandatory = $true)] $ClusterApplicationId,
   [string] [Parameter(Mandatory = $true)] $ClientApplicationId
)

. "$PSScriptRoot\Common.ps1" # this is the path. the system will look for the file in the current directory

$ResourceGroupName = "ASF-$Name"  # Resource group everything will be created in
$KeyVaultName = "$Name-vault"     # name of the Key Vault
$rdpPassword = "Password00;;"

#Add-AzAccount 

# Check that you're logged in to Azure before running anything at all, the call will
# exit the script if you're not
CheckLoggedIn

#Select a subscription becuase the logged in user might not have access to a subscription
##Get-AzSubscription -SubscriptionName "Windows Azure MSDN - Visual Studio Ultimate" | Select-AzSubscription
Get-AzSubscription -SubscriptionName "Windows Azure MSDN - Visual Studio Professional" | Select-AzSubscription

# Ensure resource group we are deploying to exists.
EnsureResourceGroup $ResourceGroupName $Location

# Ensure that the Key Vault resource exists.
$keyVault = EnsureKeyVault $KeyVaultName $ResourceGroupName $Location

# Ensure that self-signed certificate is created and imported into Key Vault
$cert = EnsureSelfSignedCertificate $KeyVaultName $Name

Write-Host "Applying cluster template $TemplateName..."
$armParameters = @{
    namePart = $Name;
    certificateThumbprint = $cert.Thumbprint;
    sourceVaultResourceId = $keyVault.ResourceId;
    certificateUrlValue = $cert.SecretId;
    rdpPassword = $rdpPassword;
    vmInstanceCount = 1;  # will create 1 node it is cheaper. 5 required minimum of nodes for a silver
    aadTenantId = $TenantId;
    aadClusterApplicationId = $ClusterApplicationId;
    aadClientApplicationId = $ClientApplicationId;
  }

New-AzResourceGroupDeployment `
  -ResourceGroupName $ResourceGroupName `
  -TemplateFile "$PSScriptRoot\$TemplateName" `
  -Mode Incremental `
  -TemplateParameterObject $armParameters `
  -Verbose