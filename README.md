# Guardicore Azure Data Collection Tool

## Overview
This script collects information about your Azure environment to help Guardicore design an optimal labeling strategy for micro-segmentation. The collection is **read-only** and makes no changes to your Azure environment.

## What Data is Collected?
- Azure subscriptions
- Resources (VMs, databases, storage accounts, etc.)
- Resource tags
- Resource groups
- Virtual networks and subnets
- Network security groups and rules
- Network interfaces and IP assignments

**No sensitive data** like passwords, keys, or secrets are collected.

## Prerequisites
- Azure CloudShell access (no installation required)
- **Reader** role on Azure subscriptions you want to assess
- Approximately 5-10 minutes depending on environment size

## Instructions

### Step 1: Open Azure CloudShell
1. Log into [Azure Portal](https://portal.azure.com)
2. Click the **CloudShell** icon in the top navigation bar (looks like `>_`)
3. Select **PowerShell** when prompted (if this is your first time)
4. Wait for CloudShell to initialize

### Step 2: Run the Collection Script
Copy and paste this command into CloudShell:
"```bashcurl -sL https://[YOUR-SCRIPT-URL]/Collect-AzureData.ps1 | pwsh"

Press **Enter** to execute.

### Step 3: Provide Company Name
When prompted, enter your company or customer name:Enter company/customer name (no spaces): Contoso
> **Tip:** Use hyphens or underscores instead of spaces (e.g., `Contoso-Corp`)

### Step 4: Wait for Collection
The script will display progress as it collects data:[10%] Discovery - Getting subscriptions
Found 3 enabled subscription(s)Processing subscription 1 of 3: Production
Found 247 resources
Found 12 resource groups
Found 3 virtual networks
Found 8 network security groups
Found 45 network interfaces
...

This typically takes **5-10 minutes** for most environments.

### Step 5: Download the ZIP File
When complete, you'll see:╔════════════════════════════════════════════════════════╗
║              COLLECTION COMPLETE                       ║
╚════════════════════════════════════════════════════════╝Output file: AzureData_Contoso_20250120_143022.zip
Location: ~/clouddrive/AzureData_Contoso_20250120_143022.zip═══════════════════════════════════════════════════════
NEXT STEPS:
═══════════════════════════════════════════════════════

Click the Upload/Download button in CloudShell toolbar
Select 'Download'
Enter path: clouddrive/AzureData_Contoso_20250120_143022.zip
Email the downloaded ZIP file to your Guardicore TAM
═══════════════════════════════════════════════════════


**To download:**
1. Click the **Upload/Download files** button in the CloudShell toolbar (📁 icon)
2. Select **Download**
3. Copy/paste the file path shown in the outputclouddrive/AzureData_Contoso_20250120_143022.zip
4. Click **Download**
5. Save the file to your computer

### Step 6: Send to Your TAM
Email the downloaded ZIP file to your Guardicore Technical Account Manager.

**Subject:** Azure Assessment Data - [Your Company Name]

---

## Troubleshooting

### "Cannot find Az module"
**Solution:** Azure CloudShell has Az modules pre-installed. Make sure you selected **PowerShell** (not Bash) when CloudShell started.

### "Access Denied" or "Insufficient Permissions"
**Solution:** You need at least **Reader** role on the subscriptions. Contact your Azure administrator to grant access.

### Script appears to hang
**Solution:** Large environments (1000+ resources) can take 15-20 minutes. Watch for progress updates. If truly stuck for 30+ minutes, press `Ctrl+C` and contact your TAM.

### Can't find the ZIP file
**Solution:** The file is in your CloudShell storage at `~/clouddrive/`. You can verify with:
```bashls ~/clouddrive/*.zip

### CloudShell times out
**Solution:** CloudShell sessions timeout after 20 minutes of inactivity. If this happens during collection, simply re-run the script. It will create a new collection.

### Download button is grayed out
**Solution:** 
1. Make sure CloudShell is active (not disconnected)
2. Try refreshing the browser
3. Verify the file exists: `ls ~/clouddrive/*.zip`

---

## What's Inside the ZIP?

The ZIP file contains:
- `metadata.json` - Collection timestamp and summary statistics
- `subscriptions.csv` - List of Azure subscriptions
- `resources.csv` - All Azure resources with metadata
- `tags.csv` - Resource tags in normalized format
- `resource_groups.csv` - Resource group details
- `vnets.csv` - Virtual network configurations
- `subnets.csv` - Subnet details and associations
- `nsgs.csv` - Network security group inventory
- `nsg_rules.csv` - Individual NSG rules
- `network_interfaces.csv` - NIC and IP information

---

## Security & Privacy

### What permissions does the script need?
**Reader** role only. The script cannot make any changes to your Azure environment.

### Is any sensitive data collected?
No. The script collects:
- ✅ Resource names and types
- ✅ Network topology
- ✅ Tag keys and values
- ✅ IP addresses and subnets

The script does NOT collect:
- ❌ Passwords or secrets
- ❌ Access keys
- ❌ Connection strings
- ❌ Certificate data
- ❌ Application data

### Where is the data stored?
The data is stored temporarily in your CloudShell storage (`~/clouddrive/`) until you download it. You control the file and decide when to share it with your TAM.

### Can I review the data before sending?
Yes! After the script completes, you can extract and review the ZIP file before sending it to your TAM.

---

## Estimated Collection Times

| Environment Size | Estimated Time |
|-----------------|----------------|
| Small (< 100 resources) | 2-3 minutes |
| Medium (100-500 resources) | 5-7 minutes |
| Large (500-1000 resources) | 8-12 minutes |
| Very Large (1000+ resources) | 15-25 minutes |

---

## Support

### Questions before running?
Contact your Guardicore TAM:
- **Email:** [TAM email]
- **Phone:** [TAM phone]

### Issues during collection?
1. Take a screenshot of the error
2. Note where in the process it failed
3. Email your TAM with details

### Need to re-run?
No problem! You can run the script multiple times. Each run creates a uniquely timestamped ZIP file.

---

## FAQ

**Q: Will this script make any changes to my Azure environment?**  
A: No. The script is completely read-only. It only queries and exports data.

**Q: How long is the data retained?**  
A: The data stays in your CloudShell storage until you manually delete it. We recommend deleting it after your TAM confirms receipt.

**Q: Can I run this on specific subscriptions only?**  
A: Currently, the script collects from all enabled subscriptions you have Reader access to. If you need to limit scope, contact your TAM for a customized version.

**Q: What if I have multiple Azure tenants?**  
A: Run the script once per tenant. CloudShell operates within a single tenant context.

**Q: Is there a size limit for the ZIP file?**  
A: CloudShell storage has a 5GB limit. Typical collections are 1-50MB, so this shouldn't be an issue.

**Q: Can I automate this collection?**  
A: For recurring assessments, contact your TAM about automation options.

---

## What Happens Next?

After you send the ZIP file to your TAM:

1. **Analysis (1-2 days):** Your TAM will analyze your Azure environment and correlate it with Guardicore labeling best practices

2. **Recommendations:** You'll receive:
   - Proposed labeling schema (Environment, Application, Role, etc.)
   - Tag-to-label mapping recommendations
   - Network segmentation opportunities
   - Gap analysis and prioritization

3. **Review Session:** Schedule a call with your TAM to review findings and finalize your labeling strategy

4. **Implementation Planning:** Create an action plan for implementing Guardicore labels in your environment

---

**Questions? Contact your Guardicore TAM**
