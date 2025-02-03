# WordPress Deployment Project

This repository contains a WordPress website with automated deployment using GitHub Actions. The project includes a CI/CD pipeline that automatically deploys changes to a VPS when code is pushed to the master branch.

## 🚀 Quick Links
- Production Site: [https://wordpressassignment.convertcurrency.online](https://wordpressassignment.convertcurrency.online)

## 📋 Prerequisites

- PHP 8.1 or higher
- MySQL 5.7 or higher
- Nginx or Apache
- Git
- WP-CLI (optional but recommended)

## 🛠️ Local Development Setup

1. **Clone the Repository**
   ```bash
   git clone https://github.com/gargkrishna730/WordPress-Assignment.git
   cd WordPress-Assignment
   ```

2. **Download WordPress**
   ```bash
   # Download latest WordPress
   wget https://wordpress.org/latest.zip
   unzip latest.zip
   mv wordpress/* wordpress-project/
   rm -rf wordpress latest.zip
   ```

3. **Set up Local Environment**
   ```bash
   # Copy sample config
   cp wordpress-project/wp-config-sample.php wordpress-project/wp-config.php
   
   # Update database credentials in wp-config.php
   define('DB_NAME', 'your_local_db_name');
   define('DB_USER', 'your_local_db_user');
   define('DB_PASSWORD', 'your_local_db_password');
   define('DB_HOST', 'localhost');
   ```

4. **Create Local Database**
   ```bash
   mysql -u root -p
   CREATE DATABASE wordpressassignment;
   ```

5. **Set up Local Server**
   ```bash
   # For PHP's built-in server (development only)
   cd wordpress-project
   php -S localhost:8000
   
   # Or configure Nginx/Apache to point to wordpress-project directory
   ```

6. **Complete WordPress Installation**
   - Visit http://localhost:8000
   - Follow the WordPress installation wizard
   - Set up your admin account

## 🔄 GitHub Actions Workflow

The deployment workflow (.github/workflows/deploy.yml) automatically:
1. Runs code analysis
2. Deploys to production server
3. Performs security scanning
4. Sends email notifications

### Required GitHub Secrets

Set these in your repository settings:
- `EMAIL_USERNAME`: Email for notifications
- `EMAIL_PASSWORD`: Email app password
- `NOTIFICATION_EMAIL`: Where to send notifications

## 🚀 Deployment Process

1. **Push to Master Branch**
   ```bash
   git add .
   git commit -m "Your changes"
   git push origin master
   ```

2. **Automatic Deployment**
   - GitHub Actions will trigger automatically
   - Changes will be deployed to production
   - You'll receive an email notification

## 🔒 Security

- Weekly automated security scans using WPScan
- PHP code linting on every push
- Secure file permissions handling
- NGINX configuration validation

## 📁 Project Structure 

- .github/workflows/deploy.yml: Deployment workflow
- wordpress-project/: WordPress project files
- README.md: This file


## 🤝 Contributing

1. Create a feature branch
2. Make your changes
3. Submit a pull request
4. Wait for CI checks to pass

## ⚠️ Important Notes

- Never commit wp-config.php
- Keep plugins and themes updated
- Review security scan reports
- Test changes locally before pushing

## 📧 Support

For issues or questions:
1. Open a GitHub issue
2. Include detailed description
3. Add relevant logs/screenshots