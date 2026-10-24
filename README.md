# Craft CMS Template for Quant Cloud

[![Deploy to Quant Cloud](https://www.quantcdn.io/img/quant-deploy-btn-sml.svg)](https://dashboard.quantcdn.io/deploy/app/app-craft-cms)

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

3. Set your own secrets in `docker-compose.override.yml`. The container does not
   start while `CRAFT_SECURITY_KEY` or `CRAFT_ADMIN_PASSWORD` is empty or still holds
   an example value. Generate the values with:
   ```bash
   openssl rand -hex 24   # CRAFT_SECURITY_KEY
   openssl rand -hex 12   # CRAFT_ADMIN_PASSWORD
   ```

4. Start the containers:
   ```bash
   docker-compose up -d
   ```

5. Wait for the containers to be ready, then access:
   - **Site**: http://localhost
   - **Control Panel**: http://localhost/admin

6. Craft installs on first start with the admin user and password you set. Sign in
   at the control panel and change the password.

### Secrets on Quant Cloud

On Quant Cloud, `CRAFT_SECURITY_KEY` and `CRAFT_ADMIN_PASSWORD` are generated when you
deploy and are stored as application secrets. Read `CRAFT_ADMIN_PASSWORD` from the
application secrets for the first login, then change it in the control panel.
An existing site that still holds an earlier example value must set a new secret
before the container starts.

Warning: do not change `CRAFT_SECURITY_KEY` on a live site. Craft cannot read data that it
encrypted with the old key. Enter the affected settings again after any key change.

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `CRAFT_ENVIRONMENT` | Environment name (dev, staging, production) | `production` |
| `CRAFT_SECURITY_KEY` | Security key for encryption (required, generated on Quant Cloud) | - |
| `CRAFT_ADMIN_PASSWORD` | Initial admin password, used on first install only (required, generated on Quant Cloud) | - |
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
├── scripts/lint-compose-secrets.sh  # Rejects literal secrets in compose files
├── tests/                      # Secret guard and lint tests
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
