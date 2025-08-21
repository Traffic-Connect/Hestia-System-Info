<?php

class SystemInfo
{
    public static function getCpuInfo(): array
    {
        $cpu = [];
        if (file_exists('/proc/cpuinfo')) {
            $cpuData = file_get_contents('/proc/cpuinfo');
            if (preg_match('/model name\s+:\s+(.+)/', $cpuData, $m)) {
                $cpu['model'] = trim($m[1]);
            }
        }
        if (empty($cpu['model'])) {
            $cpuModel = shell_exec('lscpu | grep "Model name" | cut -d: -f2 | xargs');
            if ($cpuModel) {
                $cpu['model'] = trim($cpuModel);
            }
        }
        return $cpu;
    }

    public static function getDiskInfo(): array
    {
        $info = [];
        $dfOutput = shell_exec("df -h / | tail -1");
        $parts = preg_split('/\s+/', trim($dfOutput));
        if (count($parts) >= 5) {
            $info['usage_percent'] = (int) str_replace('%', '', $parts[4]);
            $info['total'] = trim($parts[1]);
            $info['used'] = trim($parts[2]);
            $info['available'] = trim($parts[3]);
        } else {
            $usage = shell_exec("df -h / | tail -1 | awk '{print \$5}' | sed 's/%//'");
            $total = shell_exec("df -h / | tail -1 | awk '{print \$2}'");
            $used = shell_exec("df -h / | tail -1 | awk '{print \$3}'");
            $avail = shell_exec("df -h / | tail -1 | awk '{print \$4}'");
            $info['usage_percent'] = (int) trim($usage);
            $info['total'] = trim($total);
            $info['used'] = trim($used);
            $info['available'] = trim($avail);
        }
        return $info;
    }

    public static function getRamInfo(): array
    {
        $info = [];
        $total = shell_exec("free -h | grep '^Mem:' | awk '{print \$2}'");
        $used = shell_exec("free -h | grep '^Mem:' | awk '{print \$3}'");
        $free = shell_exec("free -h | grep '^Mem:' | awk '{print \$4}'");
        $info['total'] = trim($total);
        $info['used'] = trim($used);
        $info['free'] = trim($free);
        $totalMb = shell_exec("free -m | grep '^Mem:' | awk '{print \$2}'");
        $usedMb = shell_exec("free -m | grep '^Mem:' | awk '{print \$3}'");
        if ($totalMb && $usedMb) {
            $totalMb = (float) trim($totalMb);
            $usedMb = (float) trim($usedMb);
            if ($totalMb > 0) {
                $info['usage_percent'] = round(($usedMb / $totalMb) * 100, 1);
            }
        }
        if (!isset($info['usage_percent'])) {
            $info['usage_percent'] = 0;
        }
        return $info;
    }

    public static function getBackupInfo(): array
    {
        $enabled = false;
        if (file_exists('/usr/local/hestia/data/templates/backup/remote.conf')) {
            $cfg = file_get_contents('/usr/local/hestia/data/templates/backup/remote.conf');
            if (strpos($cfg, 'BACKUP_REMOTE_ENABLED=yes') !== false) {
                $enabled = true;
            }
        }
        if (!$enabled) {
            $jobs = shell_exec('crontab -l 2>/dev/null | grep -i backup');
            if ($jobs) {
                $enabled = true;
            }
        }
        if (!$enabled) {
            $rsync = shell_exec('find /etc -name "*rsync*" -type f 2>/dev/null | head -1');
            if ($rsync) {
                $enabled = true;
            }
        }
        return [
            'enabled' => $enabled,
            'status' => $enabled ? 'active' : 'disabled',
        ];
    }

    public static function getRootFolders(): array
    {
        $result = [];
        $folders = ['link-manager', 'google-auth', 'tc-api-site-details'];
        foreach ($folders as $folder) {
            $path = '/root/' . $folder;
            $exists = is_dir($path);
            $perms = null;
            if ($exists) {
                $perms = substr(sprintf('%o', fileperms($path)), -4);
            }
            $result[$folder] = [
                'exists' => $exists,
                'path' => $path,
                'permissions' => $perms,
            ];
        }
        return $result;
    }
}
