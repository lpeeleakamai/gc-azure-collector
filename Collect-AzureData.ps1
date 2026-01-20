<#
.SYNOPSIS
    Guardicore Azure Environment Data Collection Script
.DESCRIPTION
    Collects Azure resource inventory, network topology, and tagging data for Guardicore labeling assessment.
    Read-only script - makes no changes to your Azure environment.
.NOTES
    Requires: Azure PowerShell module (pre-installed in CloudShell)
    Permissions: Reader role on subscriptions
#>

#Requires -Modules Az.Accounts, Az.Resources, Az.Network

[CmdletBinding()]
param()

# Script metadata
$scriptVersion = "1.0.0"
$scriptDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# Helper function for progress
function Write-Progress-Custom {
    param($Activity, $Status, $PercentComplete)
    Write-Host "[$PercentComplete%] $Activity - $Status" -ForegroundColor Cyan
}

# Start
Clear-Host
Write-Host "╔════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║   Guardicore Azure Data Collection Tool v$scriptVersion      ║" -ForegroundColor Green
Write-Host "║   Read-only assessment - No changes will be made       ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

# Get company name
$companyName = Read-Host "Enter company/customer name (no spaces)"
$companyName = $companyName -replace '[^a-zA-Z0-9-_]', '_'
if ([string]::IsNullOrWhiteSpace($companyName)) {
    $companyName = "Customer"
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$outputFolder = "AzureData_${companyName}_${timestamp}"
$outputPath = Join-Path $HOME "clouddrive" $outputFolder
$zipFileName = "$outputFolder.zip"
$zipPath = Join-Path $HOME "clouddrive" $zipFileName

# Create output directory
Write-Host "Creating output directory..." -ForegroundColor Yellow
New-Item -ItemType Directory -Path $outputPath -Force | Out-Null

# Initialize collections
$allResources = @()
$allTags = @()
$allResourceGroups = @()
$allVNets = @()
$allSubnets = @()
$allNSGs = @()
$allNSGRules = @()
$allNICs = @()
$allSubscriptions = @()

# Step 1: Get all subscriptions
Write-Progress-Custom -Activity "Discovery" -Status "Getting subscriptions" -PercentComplete 5
try {
    $subscriptions = Get-AzSubscription | Where-Object { $_.State -eq 'Enabled' }
    $totalSubs = $subscriptions.Count
    Write-Host "Found $totalSubs enabled subscription(s)" -ForegroundColor Green
    
    foreach ($sub in $subscriptions) {
        $allSubscriptions += [PSCustomObject]@{
            SubscriptionId = $sub.Id
            SubscriptionName = $sub.Name
            TenantId = $sub.TenantId
            State = $sub.State
        }
    }
} catch {
    Write-Host "Error getting subscriptions: $_" -ForegroundColor Red
    exit 1
}

# Step 2: Loop through each subscription
$currentSub = 0
foreach ($subscription in $subscriptions) {
    $currentSub++
    $subProgress = [math]::Round(($currentSub / $totalSubs) * 90) + 5
    
    Write-Host ""
    Write-Host "Processing subscription $currentSub of $totalSubs : $($subscription.Name)" -ForegroundColor Cyan
    
    try {
        Set-AzContext -SubscriptionId $subscription.Id -ErrorAction Stop | Out-Null
    } catch {
        Write-Host "  ⚠ Unable to access subscription: $($subscription.Name)" -ForegroundColor Yellow
        continue
    }
    
    # Collect Resources
    Write-Progress-Custom -Activity "Collection" -Status "Resources from $($subscription.Name)" -PercentComplete $subProgress
    try {
        $resources = Get-AzResource
        Write-Host "  Found $($resources.Count) resources" -ForegroundColor Gray
        
        foreach ($resource in $resources) {
            $allResources += [PSCustomObject]@{
                SubscriptionId = $subscription.Id
                SubscriptionName = $subscription.Name
                ResourceId = $resource.ResourceId
                ResourceName = $resource.Name
                ResourceType = $resource.ResourceType
                ResourceGroupName = $resource.ResourceGroupName
                Location = $resource.Location
                Kind = $resource.Kind
                Sku = $resource.Sku.Name
                CreatedTime = $resource.CreatedTime
                ChangedTime = $resource.ChangedTime
            }
            
            # Extract tags
            if ($resource.Tags) {
                foreach ($tag in $resource.Tags.GetEnumerator()) {
                    $allTags += [PSCustomObject]@{
                        SubscriptionId = $subscription.Id
                        ResourceId = $resource.ResourceId
                        ResourceName = $resource.Name
                        ResourceType = $resource.ResourceType
                        TagKey = $tag.Key
                        TagValue = $tag.Value
                    }
                }
            }
        }
    } catch {
        Write-Host "  ⚠ Error collecting resources: $_" -ForegroundColor Yellow
    }
    
    # Collect Resource Groups
    Write-Progress-Custom -Activity "Collection" -Status "Resource Groups from $($subscription.Name)" -PercentComplete ($subProgress + 1)
    try {
        $resourceGroups = Get-AzResourceGroup
        Write-Host "  Found $($resourceGroups.Count) resource groups" -ForegroundColor Gray
        
        foreach ($rg in $resourceGroups) {
            $rgTags = if ($rg.Tags) { ($rg.Tags.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join '; ' } else { '' }
            
            $allResourceGroups += [PSCustomObject]@{
                SubscriptionId = $subscription.Id
                SubscriptionName = $subscription.Name
                ResourceGroupName = $rg.ResourceGroupName
                Location = $rg.Location
                ProvisioningState = $rg.ProvisioningState
                Tags = $rgTags
            }
        }
    } catch {
        Write-Host "  ⚠ Error collecting resource groups: $_" -ForegroundColor Yellow
    }
    
    # Collect VNets
    Write-Progress-Custom -Activity "Collection" -Status "Virtual Networks from $($subscription.Name)" -PercentComplete ($subProgress + 2)
    try {
        $vnets = Get-AzVirtualNetwork
        Write-Host "  Found $($vnets.Count) virtual networks" -ForegroundColor Gray
        
        foreach ($vnet in $vnets) {
            $addressPrefixes = $vnet.AddressSpace.AddressPrefixes -join ', '
            $dnsServers = $vnet.DhcpOptions.DnsServers -join ', '
            
            $allVNets += [PSCustomObject]@{
                SubscriptionId = $subscription.Id
                SubscriptionName = $subscription.Name
                VNetName = $vnet.Name
                ResourceGroupName = $vnet.ResourceGroupName
                Location = $vnet.Location
                AddressPrefixes = $addressPrefixes
                DnsServers = $dnsServers
                EnableDdosProtection = $vnet.EnableDdosProtection
                SubnetCount = $vnet.Subnets.Count
            }
            
            # Collect Subnets from this VNet
            foreach ($subnet in $vnet.Subnets) {
                $nsgName = if ($subnet.NetworkSecurityGroup) { $subnet.NetworkSecurityGroup.Id.Split('/')[-1] } else { '' }
                
                $allSubnets += [PSCustomObject]@{
                    SubscriptionId = $subscription.Id
                    VNetName = $vnet.Name
                    SubnetName = $subnet.Name
                    AddressPrefix = $subnet.AddressPrefix
                    NetworkSecurityGroup = $nsgName
                    ResourceCount = ($subnet.IpConfigurations.Count + $subnet.ResourceNavigationLinks.Count)
                }
            }
        }
    } catch {
        Write-Host "  ⚠ Error collecting virtual networks: $_" -ForegroundColor Yellow
    }
    
    # Collect NSGs
    Write-Progress-Custom -Activity "Collection" -Status "Network Security Groups from $($subscription.Name)" -PercentComplete ($subProgress + 3)
    try {
        $nsgs = Get-AzNetworkSecurityGroup
        Write-Host "  Found $($nsgs.Count) network security groups" -ForegroundColor Gray
        
        foreach ($nsg in $nsgs) {
            $associatedSubnets = ($nsg.Subnets | ForEach-Object { $_.Id.Split('/')[-1] }) -join ', '
            $associatedNICs = $nsg.NetworkInterfaces.Count
            
            $allNSGs += [PSCustomObject]@{
                SubscriptionId = $subscription.Id
                NSGName = $nsg.Name
                ResourceGroupName = $nsg.ResourceGroupName
                Location = $nsg.Location
                AssociatedSubnets = $associatedSubnets
                AssociatedNICCount = $associatedNICs
                SecurityRuleCount = $nsg.SecurityRules.Count
                DefaultRuleCount = $nsg.DefaultSecurityRules.Count
            }
            
            # Collect NSG Rules
            foreach ($rule in $nsg.SecurityRules) {
                $allNSGRules += [PSCustomObject]@{
                    SubscriptionId = $subscription.Id
                    NSGName = $nsg.Name
                    RuleName = $rule.Name
                    Priority = $rule.Priority
                    Direction = $rule.Direction
                    Access = $rule.Access
                    Protocol = $rule.Protocol
                    SourceAddressPrefix = ($rule.SourceAddressPrefix -join ', ')
                    SourcePortRange = ($rule.SourcePortRange -join ', ')
                    DestinationAddressPrefix = ($rule.DestinationAddressPrefix -join ', ')
                    DestinationPortRange = ($rule.DestinationPortRange -join ', ')
                    Description = $rule.Description
                }
            }
        }
    } catch {
        Write-Host "  ⚠ Error collecting network security groups: $_" -ForegroundColor Yellow
    }
    
    # Collect Network Interfaces
    Write-Progress-Custom -Activity "Collection" -Status "Network Interfaces from $($subscription.Name)" -PercentComplete ($subProgress + 4)
    try {
        $nics = Get-AzNetworkInterface
        Write-Host "  Found $($nics.Count) network interfaces" -ForegroundColor Gray
        
        foreach ($nic in $nics) {
            $vmId = if ($nic.VirtualMachine) { $nic.VirtualMachine.Id } else { '' }
            $vmName = if ($vmId) { $vmId.Split('/')[-1] } else { '' }
            
            foreach ($ipConfig in $nic.IpConfigurations) {
                $subnetId = $ipConfig.Subnet.Id
                $vnetName = if ($subnetId) { $subnetId.Split('/')[-3] } else { '' }
                $subnetName = if ($subnetId) { $subnetId.Split('/')[-1] } else { '' }
                $publicIpId = $ipConfig.PublicIpAddress.Id
                $publicIp = if ($publicIpId) { (Get-AzPublicIpAddress -ResourceGroupName $nic.ResourceGroupName -Name $publicIpId.Split('/')[-1] -ErrorAction SilentlyContinue).IpAddress } else { '' }
                
                $allNICs += [PSCustomObject]@{
                    SubscriptionId = $subscription.Id
                    NICName = $nic.Name
                    ResourceGroupName = $nic.ResourceGroupName
                    Location = $nic.Location
                    AttachedVMName = $vmName
                    VNetName = $vnetName
                    SubnetName = $subnetName
                    PrivateIP = $ipConfig.PrivateIpAddress
                    PublicIP = $publicIp
                    IsPrimary = $ipConfig.Primary
                }
            }
        }
    } catch {
        Write-Host "  ⚠ Error collecting network interfaces: $_" -ForegroundColor Yellow
    }
}

# Step 3: Export to CSV
Write-Progress-Custom -Activity "Export" -Status "Writing CSV files" -PercentComplete 95
Write-Host ""
Write-Host "Exporting data to CSV files..." -ForegroundColor Yellow

# Create metadata
$metadata = @{
    ScriptVersion = $scriptVersion
    CollectionDate = $scriptDate
    CompanyName = $companyName
    TotalSubscriptions = $allSubscriptions.Count
    TotalResources = $allResources.Count
    TotalResourceGroups = $allResourceGroups.Count
    TotalVNets = $allVNets.Count
    TotalSubnets = $allSubnets.Count
    TotalNSGs = $allNSGs.Count
    TotalNICs = $allNICs.Count
} | ConvertTo-Json

$metadata | Out-File -FilePath (Join-Path $outputPath "metadata.json") -Encoding UTF8

# Export CSVs
$allSubscriptions | Export-Csv -Path (Join-Path $outputPath "subscriptions.csv") -NoTypeInformation -Encoding UTF8
$allResources | Export-Csv -Path (Join-Path $outputPath "resources.csv") -NoTypeInformation -Encoding UTF8
$allTags | Export-Csv -Path (Join-Path $outputPath "tags.csv") -NoTypeInformation -Encoding UTF8
$allResourceGroups | Export-Csv -Path (Join-Path $outputPath "resource_groups.csv") -NoTypeInformation -Encoding UTF8
$allVNets | Export-Csv -Path (Join-Path $outputPath "vnets.csv") -NoTypeInformation -Encoding UTF8
$allSubnets | Export-Csv -Path (Join-Path $outputPath "subnets.csv") -NoTypeInformation -Encoding UTF8
$allNSGs | Export-Csv -Path (Join-Path $outputPath "nsgs.csv") -NoTypeInformation -Encoding UTF8
$allNSGRules | Export-Csv -Path (Join-Path $outputPath "nsg_rules.csv") -NoTypeInformation -Encoding UTF8
$allNICs | Export-Csv -Path (Join-Path $outputPath "network_interfaces.csv") -NoTypeInformation -Encoding UTF8

Write-Host "✓ CSV files created" -ForegroundColor Green

# Step 4: Create ZIP
Write-Progress-Custom -Activity "Packaging" -Status "Creating ZIP file" -PercentComplete 98
try {
    Compress-Archive -Path $outputPath -DestinationPath $zipPath -Force
    Write-Host "✓ ZIP file created: $zipFileName" -ForegroundColor Green
    
    # Clean up folder
    Remove-Item -Path $outputPath -Recurse -Force
} catch {
    Write-Host "⚠ Error creating ZIP: $_" -ForegroundColor Red
    Write-Host "Files are available in: $outputPath" -ForegroundColor Yellow
}

# Step 5: Summary and instructions
Write-Progress-Custom -Activity "Complete" -Status "Collection finished" -PercentComplete 100
Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║              COLLECTION COMPLETE                       ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  Subscriptions: $($allSubscriptions.Count)" -ForegroundColor White
Write-Host "  Resources: $($allResources.Count)" -ForegroundColor White
Write-Host "  Resource Groups: $($allResourceGroups.Count)" -ForegroundColor White
Write-Host "  VNets: $($allVNets.Count)" -ForegroundColor White
Write-Host "  Subnets: $($allSubnets.Count)" -ForegroundColor White
Write-Host "  NSGs: $($allNSGs.Count)" -ForegroundColor White
Write-Host "  Network Interfaces: $($allNICs.Count)" -ForegroundColor White
Write-Host ""
Write-Host "Output file: $zipFileName" -ForegroundColor Yellow
Write-Host "Location: ~/clouddrive/$zipFileName" -ForegroundColor Yellow
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "NEXT STEPS:" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "1. Click the Upload/Download button in CloudShell toolbar" -ForegroundColor White
Write-Host "2. Select 'Download'" -ForegroundColor White
Write-Host "3. Enter path: clouddrive/$zipFileName" -ForegroundColor White
Write-Host "4. Email the downloaded ZIP file to your Guardicore TAM" -ForegroundColor White
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""