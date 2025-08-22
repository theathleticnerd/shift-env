# Synup Shift Staging Environment Script

A simple bash script for managing Synup staging environments through nginx configuration. This tool allows developers to easily switch between different staging environments (dev1-1, dev1-2, dev2-1, dev2-2, dev3-1, dev5-1) with interactive menus and automatic nginx service management.

## Prerequisites

- nginx installed via Homebrew or system-wide
- Access to the synup.conf configuration file

## Installation

### 1. Clone the repository

```bash
git clone https://github.com/theathleticnerd/shift-env.git
cd shift-env
```

### 2. Make the script executable

```bash
chmod +x shift_env.sh
```

### 3. Customize the configuration file path (Optional)

If your nginx configuration file is located in a different path, you can modify the script:

```bash
# Open the script in your preferred editor
nano shift_env.sh
# or
vim shift_env.sh
```

Find line 5 and update the `CONFIG_FILE` variable:

```bash
CONFIG_FILE="/opt/homebrew/etc/nginx/servers/synup.conf"
```

Change it to match your installation path, for example:

- Homebrew installation: `/opt/homebrew/etc/nginx/servers/synup.conf`
- System installation: `/etc/nginx/sites-available/synup.conf`
- Custom location: `/path/to/your/synup.conf`

**Alternative: Use Environment Variable**

You can also set the configuration file path using an environment variable without modifying the script:

```bash
# Add this to your ~/.zshrc file
export SYNUP_CONFIG_FILE="/path/to/your/synup.conf"
```

This approach is cleaner as it doesn't require modifying the script file.

### 4. Add the script as an alias in your `.zshrc` file

```bash
# Add this line to your ~/.zshrc file
alias shift-env="/path/to/shift-env/shift_env.sh arrow"
```

Replace `/path/to/shift-env/` with the actual path to your script.

### 5. Restart your shell

```bash
source ~/.zshrc
# or
zsh
```

## Usage

### Quick Start

After setting up the alias, you can use the script simply by running:

```bash
shift-env
```

This will open the interactive arrow-key navigation menu for selecting staging environments.

### Command Line Options

The script also supports several other usage patterns:

```bash
# Show current status and available options
./shift_env.sh

# Switch to a specific environment
./shift_env.sh dev3-1

# Show current status
./shift_env.sh status

# Interactive numbered menu
./shift_env.sh menu

# Interactive arrow-key navigation (recommended)
./shift_env.sh arrow
```

### Available Environments

The script manages the following staging environments:

- `dev1-1`
- `dev1-2`
- `dev2-1`
- `dev2-2`
- `dev3-1`
- `dev5-1`

### Interactive Modes

#### Arrow Key Navigation (Recommended)

```bash
./shift_env.sh arrow
```

- Use ↑↓ arrow keys to navigate
- Press Enter to select
- Press 'q' to quit
- Shows current environment with "(current)" marker

#### Numbered Menu

```bash
./shift_env.sh menu
```

- Displays numbered list of environments
- Enter the number of your choice
- Enter '0' to cancel

## How It Works

1. **Environment Detection**: The script reads the current staging environment from the nginx configuration file
2. **Configuration Update**: Updates the `synup.conf` file with the new environment settings
3. **Service Restart**: Automatically restarts nginx to apply changes
4. **Validation**: Ensures the target environment is valid before making changes

### Configuration File

The script modifies `/opt/homebrew/etc/nginx/servers/synup.conf` and updates:

- `server` directive with the new environment
- `proxy_set_header Host` directive

## Troubleshooting

### Common Issues

**"Configuration file not found"**

- Verify the synup.conf path in your nginx configuration
- Check that the configuration file exists at the specified path
- Ensure the `SYNUP_CONFIG_FILE` environment variable is set correctly (if using custom path)

**"Could not detect current staging environment"**

- Verify the configuration file contains a valid staging environment
- Check the format: `server devX-X.stg.synup.com:443;`

**"Failed to restart nginx service"**

- Try manually restarting nginx: `brew services restart nginx`
- Or reload configuration: `sudo nginx -s reload`

### Manual Nginx Restart

If automatic restart fails, you can manually restart nginx:

```bash
# For Homebrew installation
brew services restart nginx

# For system installation
sudo nginx -s reload
```

---

Happy coding! ❤️
