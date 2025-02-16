# WordPress Bedrock Project Setup Script

This bash script automates the process of setting up a new WordPress project using Bedrock, a modern WordPress stack. It configures Nginx, creates a MySQL database, and sets up the necessary file permissions for the project.

## Prerequisites

Ensure **Composer**, **PHP**, **MySQL**, and **Nginx** are installed before running the script.

## Features

- Creates a new Bedrock project in the specified directory.
- Configures Nginx for the project with a custom `.conf` file.
- Creates a new MySQL database for the project.
- Sets up necessary file permissions.
- Adds the project to `/etc/hosts` for local development (e.g., `http://project_name.local`).
- Restarts Nginx to apply changes.

## Installation

1. Clone this repository or copy the script to your local machine.
2. Make the script executable:

   ```bash
   chmod +x setup-bedrock-project.sh
   ```
3. Run the script
   ```bash
   ./createproject.sh
   ```
4. Follow the prompts
- Enter your project name
- Provide your MySQL root password

## Workflow

1. **Checks for necessary software**: The script checks if Composer, PHP, MySQL, and Nginx are installed on your system.
2. **Project setup**: The script creates a new project directory under /var/www/, installs the Bedrock project, and sets up permissions.
3. **Database creation**: The script creates a MySQL database named after your project and assigns it to the project.
4. **Nginx configuration**: A new Nginx configuration is created under /etc/nginx/sites-available/ and a symbolic link is made in /etc/nginx/sites-enabled/.
5. **Hosts file modification**: The script ensures that the domain project_name.local is added to your /etc/hosts file for local access.
6. **Nginx reload**: The script tests and reloads the Nginx configuration to apply the changes.

## Post-Installation

After running the script successfully:
1. Configure your WordPress site by visiting `http://project_name.local`
2. Complete the WordPress installation process
3. Your WordPress files will be located in `/var/www/project_name/`
4. The database name will match your project name

## Environment Configuration

The Bedrock installation **does not** create an `.env` file in your project directory. You'll need to add it manually and update it with:
- Database credentials
- WordPress salts
- Other environment-specific configurations

## Troubleshooting
- Missing PHP or MySQL extensions: If you encounter issues related to missing extensions (e.g., mysqli), make sure they are installed and enabled in your php.ini configuration.

- Nginx configuration errors: If you run into issues with Nginx, you can manually test the configuration with sudo nginx -t.

- Permissions: If you face issues with file permissions, ensure that the project directory is owned by the www-data user for proper access.

- PHP-FPM Configuration: If you encounter 502 Bad Gateway errors, ensure PHP-FPM is running and the socket path in the Nginx configuration matches your PHP version.