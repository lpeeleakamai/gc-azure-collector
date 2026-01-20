# Guardicore Azure Data Collection

## Quick Start

### 1. Open Azure CloudShell
- Go to [portal.azure.com](https://portal.azure.com)
- Click the CloudShell icon (`>_`) in top toolbar
- Select **PowerShell** mode

### 2. Run Collection Script
```powershell
curl -sL https://raw.githubusercontent.com/lpeeleakamai/gc-azure-collector/main/Collect-AzureData.ps1 | pwsh
```

### 3. Enter Company Name
```
Enter company/customer name (no spaces): YourCompany
```

### 4. Download Results
When complete, you'll see:
```
Output file: AzureData_YourCompany_20250120_143022.zip
Location: ~/clouddrive/AzureData_YourCompany_20250120_143022.zip
```

**To download:**
1. Click **Upload/Download files** (📁) in CloudShell toolbar
2. Select **Download**
3. Enter path: `clouddrive/AzureData_YourCompany_20250120_143022.zip`
4. Save file

### 5. Email ZIP to Your TAM
Send the downloaded file to your Guardicore Technical Account Manager.

---

## What's Collected

- Subscriptions and resource groups
- Resources (VMs, storage, databases, etc.)
- Tags and metadata
- Virtual networks and subnets
- Network security groups and rules
- Network interfaces and IPs

**Read-only collection - no changes made to your environment**

---

## Requirements

- **Permissions:** Reader role on Azure subscriptions
- **Time:** 5-15 minutes (depending on environment size)
- **Access:** Azure CloudShell

---

## Troubleshooting

**"Cannot find Az module"**
- Ensure you selected **PowerShell** (not Bash) in CloudShell

**"Access Denied"**
- You need Reader role on subscriptions - contact your Azure admin

**Can't find ZIP file**
- Verify file exists: `ls ~/clouddrive/*.zip`
- File location is shown in script output

**CloudShell timeout**
- Sessions timeout after 20 minutes inactive
- Re-run the script if needed

---

## Security

**Script is read-only** - requires only Reader permissions

**Does NOT collect:**
- Passwords or secrets
- Access keys or connection strings
- Certificates
- Application data

**Does collect:**
- Resource names and types
- Network configuration
- Tags (keys and values)
- IP addresses and subnets

---

## Output Files

The ZIP contains:
- `metadata.json` - Collection summary
- `subscriptions.csv` - Subscription list
- `resources.csv` - All resources
- `tags.csv` - Resource tags
- `resource_groups.csv` - Resource groups
- `vnets.csv` - Virtual networks
- `subnets.csv` - Subnets
- `nsgs.csv` - Network security groups
- `nsg_rules.csv` - NSG rules
- `network_interfaces.csv` - Network interfaces

---

## Next Steps

After sending data to your TAM:
1. TAM analyzes environment (1-2 days)
2. Receive labeling recommendations
3. Review session with TAM
4. Implementation planning

---

## Support

Questions or issues? Contact your Guardicore TAM.

**Script source:** [github.com/lpeeleakamai/gc-azure-collector](https://github.com/lpeeleakamai/gc-azure-collector)
