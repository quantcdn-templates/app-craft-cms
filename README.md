# Craft CMS Template for Quant Cloud

[![Deploy to Quant Cloud](https://www.quantcdn.io/img/quant-deploy-btn-sml.svg)](https://dashboard.quantcdn.io/cloud-apps/create/starter-kit/app-craft-cms)

A production-ready Craft CMS template for deploying to Quant Cloud.

## Features

- **Craft CMS 5.x** - The latest version of Craft CMS
- **PHP 8.4** - Modern PHP with Apache
- **MySQL 8.4** - Production-ready database
- **Docker-based** - Consistent development and production environments
- **Quant Cloud optimized** - Pre-configured for Quant Cloud deployment

## Quick Start

### Deploy to Quant Cloud

Click the deploy button above to deploy this template directly to Quant Cloud.

### Local Development

1. Clone this repository:
   ```bash
   git clone https://github.com/quantcdn-templates/app-craft-cms.git
   cd app-craft-cms
   ```

2. Copy the environment file:
   ```bash
   cp docker-compose.override.yml.example docker-compose.override.yml
   ```

3. Generate a security key:
   ```bash
   # Use any secure random string generator
   openssl rand -base64 32
   ```
   Add the generated key to your `docker-compose.override.yml` as `CRAFT_SECURITY_KEY`.

4. Start the containers:
   ```bash
   docker-compose up -d
   ```

5. Wait for the containers to be ready, then access:
   - **Site**: http://localhost
   - **Control Panel**: http://localhost/admin

6. Complete the Craft CMS installation through the web installer.

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `CRAFT_ENVIRONMENT` | Environment name (dev, staging, production) | `production` |
| `CRAFT_SECURITY_KEY` | Security key for encryption (required) | - |
| `CRAFT_APP_ID` | Application ID | `CraftCMS` |
| `CRAFT_DEV_MODE` | Enable development mode | `false` |
| `CRAFT_ALLOW_ADMIN_CHANGES` | Allow admin changes | `false` |
| `CRAFT_DISALLOW_ROBOTS` | Add X-Robots-Tag: none | `false` |
| `PRIMARY_SITE_URL` | Primary site URL | `http://localhost` |

### Database Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `CRAFT_DB_DRIVER` | Database driver (mysql/pgsql) | `mysql` |
| `CRAFT_DB_SERVER` | Database host | `db` |
| `CRAFT_DB_PORT` | Database port | `3306` |
| `CRAFT_DB_DATABASE` | Database name | `craft` |
| `CRAFT_DB_USER` | Database user | `craft` |
| `CRAFT_DB_PASSWORD` | Database password | `craft` |
| `CRAFT_DB_TABLE_PREFIX` | Table prefix | - |

## Project Structure

```
app-craft-cms/
├── Dockerfile                  # Docker image definition
├── docker-compose.yml          # Production configuration
├── docker-compose.override.yml.example  # Local dev template
├── quant/
│   ├── meta.json               # Quant Cloud metadata
│   ├── entrypoints.sh          # Container entrypoint script
│   ├── entrypoints/            # Additional entrypoint scripts
│   └── php.ini.d/              # Custom PHP configuration
├── .github/workflows/
│   └── build-deploy.yaml       # CI/CD workflow
└── src/
    ├── composer.json           # PHP dependencies
    ├── craft                   # Craft CLI
    ├── web/                    # Web root (document root)
    │   ├── index.php           # Front controller
    │   └── .htaccess           # Apache rewrite rules
    ├── config/
    │   ├── general.php         # General configuration
    │   ├── db.php              # Database configuration
    │   └── app.php             # Application configuration
    ├── modules/                # Custom modules
    ├── storage/                # Runtime storage (logs, cache, etc.)
    └── templates/              # Twig templates
```

## Customization

### Adding Plugins

1. Add plugins via Composer:
   ```bash
   docker-compose exec craft composer require craftcms/commerce
   ```

2. Install the plugin:
   ```bash
   docker-compose exec craft php craft plugin/install commerce
   ```

### Custom PHP Configuration

Add custom PHP settings by creating files in `quant/php.ini.d/`. These will be automatically loaded.

### Custom Entrypoints

Add startup scripts in `quant/entrypoints/` to run commands when the container starts (e.g., database migrations, cache clearing).

## Deployment

### GitHub Actions

The included workflow automatically:
1. Builds the Docker image
2. Pushes to Quant Cloud registry
3. Creates/updates environments based on branch names
4. Syncs databases for new environments

### Required Secrets

Configure these in your GitHub repository settings:
- `QUANT_ORGANIZATION` - Your Quant Cloud organization slug
- `QUANT_API_KEY` - Your Quant Cloud API key

## Resources

- [Craft CMS Documentation](https://craftcms.com/docs)
- [Quant Cloud Documentation](https://docs.quantcdn.io)
- [Twig Template Documentation](https://twig.symfony.com/doc/3.x/)

## License

This template is open-source. Craft CMS itself requires a license for pro features.
