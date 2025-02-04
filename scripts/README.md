# WordPress Setup Script

This script automates the installation and configuration of WordPress on Ubuntu servers.

## Requirements

- Ubuntu 22.04 LTS
- Root or sudo privileges
- Internet connection

## What the Script Does

The setup script performs the following operations:

1. Updates system packages
2. Installs required software:
   - Apache2 web server
   - MySQL/MariaDB database
   - PHP and necessary extensions
   - Additional utilities
3. Configures Apache2 for WordPress
4. Sets up MySQL database and user for WordPress
5. Downloads and installs latest WordPress version
6. Configures basic WordPress settings
7. Sets appropriate permissions for security

## Usage

1. Make the script executable:

```bash
chmod +x setup_wordpress.sh
```

2. Run the script:

```bash
sudo ./setup_wordpress.sh
```

## Important Notes

- This script is specifically designed for Ubuntu 22.04 LTS
- Backup any existing web server configurations before running
- Make sure ports 80 and 443 are open on your firewall
- The script will prompt for:
  - MySQL root password
  - WordPress database name
  - WordPress database user
  - WordPress database password

## After Installation

After the script completes:
1. Access your WordPress site through your domain or IP address
2. Complete the WordPress installation through the web interface
3. Update your site's permalinks
4. Install necessary plugins and themes

## Troubleshooting

If you encounter any issues:
1. Check the Apache error logs: `/var/log/apache2/error.log`
2. Verify MySQL service is running: `systemctl status mysql`
3. Ensure all PHP extensions are properly installed
4. Check file permissions in the WordPress directory

## Security Recommendations

- Change default admin username
- Use strong passwords
- Keep WordPress core, themes, and plugins updated
- Install security plugins
- Configure SSL certificate
