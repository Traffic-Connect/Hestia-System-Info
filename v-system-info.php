<?php
/**
 * Custom Hestia command: v-system-info
 * Returns system information including CPU model, disk usage, RAM, backup status, and root folders
 */

// Check if running via web interface
if (isset($_SERVER['HTTP_HOST'])) {
	// Include Hestia functions if available
	if (file_exists($_SERVER['DOCUMENT_ROOT'].'/inc/main.php')) {
		include_once($_SERVER['DOCUMENT_ROOT'].'/inc/main.php');
		
		// Check if user is logged in and has admin privileges
		if (!isset($_SESSION['user']) || $_SESSION['userContext'] !== 'admin') {
			http_response_code(403);
			exit('Access denied');
		}
	} else {
		// Simple auth check if Hestia functions not available
		if (!isset($_SERVER['PHP_AUTH_USER'])) {
			header('WWW-Authenticate: Basic realm="Hestia System Info"');
			header('HTTP/1.0 401 Unauthorized');
			exit('Access denied');
		}
	}
}

// Set content type to JSON
header('Content-Type: application/json');

// Load library
$libPath = __DIR__ . '/lib/SystemInfo.php';
if (!file_exists($libPath)) {
	$libPath = '/usr/local/hestia/lib/hestia-system-info/SystemInfo.php';
}
require_once $libPath;

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
	echo json_encode(array(
		'error' => 'Internal server error',
		'message' => $e->getMessage(),
		'timestamp' => date('Y-m-d H:i:s')
	));
}
?>
