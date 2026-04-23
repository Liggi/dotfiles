#!/bin/bash

# Read JSON input from stdin
input=$(cat)

# Extract basic info
current_dir=$(echo "$input" | jq -r '.workspace.current_dir' | sed "s|$HOME|~|g")
model_name=$(echo "$input" | jq -r '.model.display_name')

# Get current date and time separately
current_date=$(date "+%b %d")
current_time=$(date "+%H:%M")

# Check for note file
note_content=""
note_file="$HOME/.claude/note"
if [[ -f "$note_file" && -s "$note_file" ]]; then
    note_content=$(cat "$note_file" | head -n 1)  # Get first line only
fi

# Get ash env profile
ash_profile=""
config_file="$HOME/.config/ash/config.yaml"
if [[ -f "$config_file" ]]; then
    ash_profile=$(yq '.current_profile' "$config_file" 2>/dev/null)
fi

# Get AlloyDB database
alloydb_db=""
internal_env="$HOME/src/slingshot-ai/ash-services-composite/ash-internal-services/services/internal/.env"
if [[ -f "$internal_env" ]]; then
    db_conn=$(grep "^DB_CONNECTION_STRING=" "$internal_env" 2>/dev/null | cut -d'=' -f2-)
    # Extract database name from jdbc:postgresql://localhost:5435/database_name
    alloydb_db=$(echo "$db_conn" | sed -n 's|.*://[^/]*/\([^?]*\).*|\1|p')
fi

# Get contracts mode
contracts_mode=""
if [[ -f "$config_file" ]]; then
    contracts_mode=$(yq '.contracts_mode' "$config_file" 2>/dev/null)
fi

# Check if overmind is running
services_status=""
overmind_socket="$HOME/src/slingshot-ai/.overmind.sock"
if [[ -S "$overmind_socket" ]]; then
    # Socket exists - assume running (checking responsiveness is too slow for statusline)
    services_status="✓"
else
    services_status="✗"
fi

# Build the status line with explicit separators
status_line="\033[32m🕐 $current_time\033[0m \033[90m|\033[0m \033[33m📅 $current_date\033[0m \033[90m|\033[0m \033[35m🤖 $model_name\033[0m \033[90m|\033[0m \033[36m📁 $current_dir\033[0m"

# Add ash-specific info if available
if [[ -n "$ash_profile" ]]; then
    status_line="$status_line \033[90m|\033[0m 🌍 environment: \033[94m$ash_profile\033[0m"  # Value in bright blue
fi
if [[ -n "$alloydb_db" ]]; then
    status_line="$status_line \033[90m|\033[0m 🗄️ alloydb: \033[95m$alloydb_db\033[0m"  # Value in bright magenta
fi
if [[ -n "$contracts_mode" ]]; then
    status_line="$status_line \033[90m|\033[0m 📦 contracts: \033[96m$contracts_mode\033[0m"  # Value in bright cyan
fi

# Add services status
if [[ -n "$services_status" ]]; then
    status_line="$status_line \033[90m|\033[0m services: "
    if [[ "$services_status" == "✓" ]]; then
        status_line="$status_line\033[92m$services_status\033[0m"  # Running (bright green)
    elif [[ "$services_status" == "⚠" ]]; then
        status_line="$status_line\033[93m$services_status\033[0m"  # Stale (bright yellow)
    else
        status_line="$status_line\033[91m$services_status\033[0m"  # Not running (bright red)
    fi
fi

# Add note if exists
if [[ -n "$note_content" ]]; then
    status_line="$status_line \033[90m|\033[0m \033[97m📝 $note_content\033[0m"  # Note (bright white)
fi

# Output the formatted status line with proper color interpretation
printf '%b' "$status_line"
