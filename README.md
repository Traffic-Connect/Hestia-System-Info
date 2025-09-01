# v-system-info

Кастомная команда для **HestiaCP**, которая возвращает сведения о системе в формате JSON.  
Удобно использовать для мониторинга и интеграции с API Hestia.  

## 📋 Возможности

`v-system-info` показывает:

- Модель процессора (`cpu_model`)  
- Версию ОС (`os_version`)  
- Версию HestiaCP (`hestia_version`)  
- Общий объём оперативной памяти (ГБ, `mem_total_gb`)  
- Информацию о корневом диске `/`:  
  - общий размер (ГБ, `disk_total_gb`)  
  - занятое место (ГБ, `disk_used_gb`)  
  - процент использования (`disk_used_pct`)  
- Настройки удалённых бэкапов:  
  - включены ли (`remote_backup_enabled`)  
  - тип системы (`remote_backup_system`)  
- Наличие папок в `/root`:  
  - `link-manager`  
  - `google-auth`  
  - `tc-api-site-details`  

## ⚙️ Установка

### 1. Скопировать скрипт

```bash
nano /usr/local/hestia/bin/v-system-info
```

### 2. Задать права

```bash
sudo chmod 750 /usr/local/hestia/bin/v-system-info && sudo chown root:root /usr/local/hestia/bin/v-system-info
```
