#!/bin/bash

# Colors (optional for callers)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

get_cpu_model() {
	# Try /proc/cpuinfo first (Linux)
	if [ -f /proc/cpuinfo ]; then
		local cpu_model=$(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)
		if [ -n "$cpu_model" ]; then
			echo "$cpu_model"
			return 0
		fi
	fi
	
	# Try lscpu command
	if command -v lscpu &> /dev/null; then
		local cpu_model=$(lscpu | grep "Model name" | cut -d: -f2 | xargs 2>/dev/null)
		if [ -n "$cpu_model" ]; then
			echo "$cpu_model"
			return 0
		fi
	fi
	
	# Try sysctl (macOS)
	if command -v sysctl &> /dev/null; then
		local cpu_model=$(sysctl -n machdep.cpu.brand_string 2>/dev/null)
		if [ -n "$cpu_model" ]; then
			echo "$cpu_model"
			return 0
		fi
	fi
	
	# Try uname for basic info
	local cpu_model=$(uname -m 2>/dev/null)
	if [ -n "$cpu_model" ]; then
		echo "$cpu_model"
		return 0
	fi
	
	# Final fallback
	echo "Unknown CPU"
}

get_disk_usage() {
	local usage=$(df -h / | tail -1 | awk '{print $5}' | sed 's/%//')
	if [ -n "$usage" ] && [ "$usage" -ge 0 ] 2>/dev/null; then
		echo "$usage"
	else
		echo "0"
	fi
}

get_disk_info() {
	local df_output=$(df -h / | tail -1)
	local total=$(echo "$df_output" | awk '{print $2}')
	local used=$(echo "$df_output" | awk '{print $3}')
	local available=$(echo "$df_output" | awk '{print $4}')
	local usage_percent=$(echo "$df_output" | awk '{print $5}' | sed 's/%//')
	if [ -n "$total" ] && [ -n "$used" ] && [ -n "$available" ] && [ -n "$usage_percent" ]; then
		echo "{\"total\":\"$total\",\"used\":\"$used\",\"available\":\"$available\",\"usage_percent\":$usage_percent}"
	else
		local basic_info=$(df -h / | tail -1)
		echo "{\"total\":\"$(echo "$basic_info" | awk '{print $2}')\",\"used\":\"$(echo "$basic_info" | awk '{print $3}')\",\"available\":\"$(echo "$basic_info" | awk '{print $4}')\",\"usage_percent\":$(echo "$basic_info" | awk '{print $5}' | sed 's/%//')}"
	fi
}

get_ram_info() {
	# Try free command first (Linux)
	if command -v free &> /dev/null; then
		local total=$(free -h | grep '^Mem:' | awk '{print $2}')
		local used=$(free -h | grep '^Mem:' | awk '{print $3}')
		local free=$(free -h | grep '^Mem:' | awk '{print $4}')
		local total_mb=$(free -m | grep '^Mem:' | awk '{print $2}')
		local used_mb=$(free -m | grep '^Mem:' | awk '{print $3}')
		
		if [ -n "$total_mb" ] && [ -n "$used_mb" ] && [ "$total_mb" -gt 0 ]; then
			local usage_percent
			if command -v bc &> /dev/null; then
				usage_percent=$(echo "scale=1; $used_mb * 100 / $total_mb" | bc -l 2>/dev/null || echo "0")
			else
				usage_percent=$(awk "BEGIN {printf \"%.1f\", $used_mb * 100 / $total_mb}")
			fi
			echo "{\"total\":\"$total\",\"used\":\"$used\",\"free\":\"$free\",\"usage_percent\":$usage_percent}"
			return 0
		fi
	fi
	
	# Try vm_stat for macOS (simplified)
	if command -v vm_stat &> /dev/null; then
		local total_ram=$(sysctl -n hw.memsize 2>/dev/null)
		local total_gb=$((total_ram / 1024 / 1024 / 1024))
		
		# Get memory usage from top command
		local mem_usage=$(top -l 1 | grep PhysMem | awk '{print $2}' | sed 's/G//')
		local mem_used=$(echo "$mem_usage" | awk -F'/' '{print $1}')
		local mem_total=$(echo "$mem_usage" | awk -F'/' '{print $2}')
		
		if [ -n "$mem_used" ] && [ -n "$mem_total" ] && [ "$mem_total" -gt 0 ]; then
			local usage_percent
			if command -v bc &> /dev/null; then
				usage_percent=$(echo "scale=1; $mem_used * 100 / $mem_total" | bc -l 2>/dev/null || echo "0")
			else
				usage_percent=$(awk "BEGIN {printf \"%.1f\", $mem_used * 100 / $mem_total}")
			fi
			
			local free_gb=$((mem_total - mem_used))
			echo "{\"total\":\"${mem_total}Gi\",\"used\":\"${mem_used}Gi\",\"free\":\"${free_gb}Gi\",\"usage_percent\":$usage_percent}"
			return 0
		fi
	fi
	
	# Fallback
	echo "{\"total\":\"N/A\",\"used\":\"N/A\",\"free\":\"N/A\",\"usage_percent\":0}"
}

check_backup_status() {
	local backup_enabled=false
	if [ -f /usr/local/hestia/data/templates/backup/remote.conf ]; then
		if grep -q "BACKUP_REMOTE_ENABLED=yes" /usr/local/hestia/data/templates/backup/remote.conf; then
			backup_enabled=true
		fi
	fi
	if [ "$backup_enabled" = false ]; then
		if crontab -l 2>/dev/null | grep -qi backup; then
			backup_enabled=true
		fi
	fi
	if [ "$backup_enabled" = false ]; then
		if find /etc -name "*rsync*" -type f 2>/dev/null | head -1 | grep -q .; then
			backup_enabled=true
		fi
	fi
	if [ "$backup_enabled" = true ]; then
		echo "{\"enabled\":true,\"status\":\"active\"}"
	else
		echo "{\"enabled\":false,\"status\":\"disabled\"}"
	fi
}

check_root_folders() {
	local folders=("link-manager" "google-auth" "tc-api-site-details")
	local result="{"
	local first=true
	for folder in "${folders[@]}"; do
		local folder_path="/root/$folder"
		if [ "$first" = true ]; then
			first=false
		else
			result="$result,"
		fi
		if [ -d "$folder_path" ]; then
			local perms=$(stat -c %a "$folder_path" 2>/dev/null || stat -f %A "$folder_path" 2>/dev/null || echo "755")
			result="$result\"$folder\":{\"exists\":true,\"path\":\"$folder_path\",\"permissions\":\"$perms\"}"
		else
			result="$result\"$folder\":{\"exists\":false,\"path\":\"$folder_path\",\"permissions\":null}"
		fi
	done
	result="$result}"
	echo "$result"
}
