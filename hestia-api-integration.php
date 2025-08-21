<?php
/**
 * Hestia API Integration for v-system-info command
 * This file provides integration with Hestia's API system
 */

// Include Hestia functions if available
if (file_exists($_SERVER['DOCUMENT_ROOT'].'/inc/main.php')) {
	include_once($_SERVER['DOCUMENT_ROOT'].'/inc/main.php');
	if (!isset($_SESSION['user']) || $_SESSION['userContext'] !== 'admin') {
		http_response_code(403);
		exit('Access denied');
	}
}

// Load library
$libPath = __DIR__ . '/lib/SystemInfo.php';
if (!file_exists($libPath)) {
	$libPath = '/usr/local/hestia/lib/hestia-system-info/SystemInfo.php';
}
require_once $libPath;

// Handle API requests
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
	handle_get_request();
} elseif ($_SERVER['REQUEST_METHOD'] === 'POST') {
	handle_post_request();
} else {
	http_response_code(405);
	exit('Method not allowed');
}

/**
 * Handle GET requests
 */
function handle_get_request() {
	$action = $_GET['action'] ?? '';
	
	switch ($action) {
		case 'system-info':
			get_system_info();
			break;
		case 'cpu':
			get_cpu_info();
			break;
		case 'disk':
			get_disk_info();
			break;
		case 'ram':
			get_ram_info();
			break;
		case 'backup':
			get_backup_info();
			break;
		case 'folders':
			get_folders_info();
			break;
		default:
			http_response_code(400);
			echo json_encode(['error' => 'Invalid action']);
			break;
	}
}

/**
 * Handle POST requests
 */
function handle_post_request() {
	$action = $_POST['action'] ?? '';
	
	switch ($action) {
		case 'system-info':
			get_system_info();
			break;
		default:
			http_response_code(400);
			echo json_encode(['error' => 'Invalid action']);
			break;
	}
}

/**
 * Get complete system information
 */
function get_system_info() {
	header('Content-Type: application/json');
	try {
		$system_info = [];
		$system_info['cpu'] = SystemInfo::getCpuInfo();
		$system_info['disk'] = SystemInfo::getDiskInfo();
		$system_info['ram'] = SystemInfo::getRamInfo();
		$system_info['remote_backup'] = SystemInfo::getBackupInfo();
		$system_info['root_folders'] = SystemInfo::getRootFolders();
		$system_info['timestamp'] = date('Y-m-d H:i:s');
		$system_info['server_timezone'] = date_default_timezone_get();
		echo json_encode($system_info, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
	} catch (Exception $e) {
		http_response_code(500);
		echo json_encode([
			'error' => 'Internal server error',
			'message' => $e->getMessage(),
			'timestamp' => date('Y-m-d H:i:s'),
		]);
	}
}

/**
 * Get CPU information only
 */
function get_cpu_info() {
	header('Content-Type: application/json');
	echo json_encode(SystemInfo::getCpuInfo(), JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
}

/**
 * Get disk information only
 */
function get_disk_info() {
	header('Content-Type: application/json');
	echo json_encode(SystemInfo::getDiskInfo(), JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
}

/**
 * Get RAM information only
 */
function get_ram_info() {
	header('Content-Type: application/json');
	echo json_encode(SystemInfo::getRamInfo(), JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
}

/**
 * Get backup information only
 */
function get_backup_info() {
	header('Content-Type: application/json');
	echo json_encode(SystemInfo::getBackupInfo(), JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
}

/**
 * Get folders information only
 */
function get_folders_info() {
	header('Content-Type: application/json');
	echo json_encode(SystemInfo::getRootFolders(), JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
}
?>
