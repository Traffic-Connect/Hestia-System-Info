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

| File | Info |
|-----------|-----------|
| **`setup.sh`**     | отвечает за установку плагина и настройку автообновлений  |
| **`update-v-system-info.sh`**   | updater,  который будет проверять обновления ежедневно в 2:25  |

### 1. Скачиваем репозиторий

```bash
git clone https://github.com/Traffic-Connect/Hestia-System-Info.git && cd Hestia-System-Info && chmod +x setup.sh
```

### 2. Запускаем установку

```bash
sudo ./setup.sh
```

### 3. Получаем результат
> === Готово ===  
> ✓ Репозиторий: /root/hestia-system-info (ветка main)  
> ✓ Плагин: /usr/local/hestia/bin/v-system-info  
> ✓ Updater: /root/hestia-system-info/update-v-system-info.sh  
> ✓ Cron: ежедневно в 02:25  
> ✓ Лог: /var/log/v-system-info.log  

> Для ручного запуска обновления:  
> sudo bash /root/hestia-system-info/update-v-system-info.sh  

> Для просмотра логов:  
> tail -f /var/log/v-system-info.log  
