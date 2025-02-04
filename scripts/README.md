# WordPress Setup Script

This script automates the installation and configuration of WordPress with NGINX on Ubuntu servers.

## Requirements

- Ubuntu 22.04 LTS
- Root or sudo privileges
- Internet connection

## What the Script Does

The setup script performs the following automated operations:

1. Updates system packages
2. Installs LEMP stack components:
   - NGINX web server
   - MySQL/MariaDB database
   - PHP 8.1 with FPM and extensions
3. Configures MySQL:
   - Sets up root password automatically
   - Creates WordPress database and user
   - Configures secure password policies
4. Sets up NGINX with:
   - Optimized configuration for WordPress
   - FastCGI caching
   - Security headers
   - GZIP compression
5. Downloads and installs latest WordPress version
6. Configures WordPress with:
   - Secure file permissions
   - Optimized wp-config.php
   - Security enhancements
7. Sets appropriate permissions for all components

## Usage

1. Make the script executable:

```bash
chmod +x setup_wordpress.sh
```

2. Run the script with sudo:

```bash
sudo ./setup_wordpress.sh
```

## Important Notes

- This script is specifically designed for Ubuntu 22.04 LTS
- Backup any existing web server configurations before running
- Make sure ports 80 and 443 are open on your firewall
- The script automatically:
  - Generates secure MySQL passwords
  - Creates database and database user
  - Saves credentials to `/home/[username]/wordpress_credentials.txt`

## After Installation

After the script completes:
1. Access your WordPress site through your domain or IP address (provided at end of installation)
2. Complete the WordPress installation through the web interface
3. Update your site's permalinks
4. Install necessary plugins and themes

## Troubleshooting

If you encounter any issues:
1. Check the NGINX error logs: `/var/log/nginx/error.log`
2. Verify services are running:
   ```bash
   systemctl status nginx
   systemctl status mysql
   systemctl status php8.1-fpm
   ```
3. Check PHP-FPM logs: `/var/log/php/error.log`
4. Verify file permissions in `/var/www/wordpress`
5. Check WordPress configuration file permissions

## Security Features

The script implements several security measures:
- Automated secure password generation
- Restricted file permissions
- FastCGI caching configuration
- Security headers in NGINX
- WordPress security constants in wp-config.php
- Protected sensitive directories
- PHP-FPM process isolation

## Additional Recommendations

- Set up SSL/HTTPS using Certbot or similar
- Configure WordPress Salts
- Implement regular backups
- Keep all components updated:
  - WordPress core
  - Themes
  - Plugins
  - NGINX
  - PHP
  - MySQL
- Consider implementing additional security measures:
  - Web Application Firewall (WAF)
  - DDoS protection
  - Regular security scanning
