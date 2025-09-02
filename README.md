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

### 1. Скачиваем репозиторий

```bash
git clone https://github.com/Traffic-Connect/Hestia-System-Info.git && cd Hestia-System-Info && chmod +x setup.sh
```

### 2. Запускаем установку

```bash
sudo ./setup.sh
```
