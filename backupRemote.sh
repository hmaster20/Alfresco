#!/bin/bash
# Remote Backup of Alfresco
# sudo mount -t cifs -o user=admin //fs01.local/backup /mnt/BackupSrv/

echo "############################" 
echo "#  Remote BackUp Alfresco  #" 
echo "############################" 

echo "$(date +%d.%m.%Y) ($(date +%H.%M:%S)) # Start script."

# Параметры:
  TIMESTAMP=$( date +%Y%m%d%H%M%S )		# Создание временной метки
  DUMP_NUM=7							# Число бэкапов
  FOLDER="/opt/alfresco-5.0.d"			# Расположение Alfresco
  FOLDER_Backup="/opt/BackUps"			# Расположение бэкапов
  FOLDER_Remote="/mnt/BackupSrv/Backup"	# Расположение удаленного хранилища

# Функция - остановка Alfresco
al_stop()
{
  sudo service alfresco stop

  # Если Alfresco не останавливается, завершить работу скрипта, чтобы не повредить индексы!
  if [ "$?" != "0" ]; then
    echo "Alfresco Stop FAILED - STOP SCRIPT!"
    exit 1;
  fi
}

# Функция - запуск Alfresco
al_start()
{
  sudo service alfresco start
}

# Проверка существования папки, переданной в качестве аргумента в строке запуска скрипта
if [ -d "$1" ]; then
  # Если папка существует, то сохранить ее в переменную
  TARGET_FOLDER="$1"
else
  # Если папка не существует, то в переменную сохранить папку по умолчанию
  TARGET_FOLDER=$FOLDER_Backup
fi


#----------------------------------------
# 1 - Begin by stopping Alfresco
#----------------------------------------

  al_stop
  echo "$(date +%d.%m.%Y) ($(date +%H.%M:%S)) # Alfresco SERVER stop."
  echo "...................................................." 
  
#----------------------------------------
# 2 - Deleting temps folders
#----------------------------------------  

# Delete temporary files (удаление временных файлов):
sudo rm -r /opt/alfresco-5.0.d/alfresco.log*
sudo rm -r /opt/alfresco-5.0.d/share.log*
sudo rm -r /opt/alfresco-5.0.d/solr.log*
sudo rm -r /opt/alfresco-5.0.d/postgresql/postgresql.log*
sudo rm -r /opt/alfresco-5.0.d/tomcat/logs/*
sudo rm -r /opt/alfresco-5.0.d/tomcat/work/*
sudo rm -r /opt/alfresco-5.0.d/tomcat/temp/*
sudo rm -r /opt/alfresco-5.0.d/tomcat/webapps/*.log
sudo rm -r /opt/alfresco-5.0.d/tomcat/webapps/*.bak
# Removal of the cached data (удаление кэша):
sudo rm -r /opt/alfresco-5.0.d/tomcat/webapps/alfresco/
sudo rm -r /opt/alfresco-5.0.d/tomcat/webapps/share/
sudo rm -r /opt/alfresco-5.0.d/tomcat/webapps/solr4/

echo "$(date +%d.%m.%Y) ($(date +%H.%M:%S)) # Temporary files and cache are removed."  

#------------------------------------------
# 3 - Create backup
#------------------------------------------

echo "...................................................." 
echo "$(date +%d.%m.%Y) ($(date +%H.%M:%S)) # Start backup."  

  # Создание бэкапа с именем, содержащем временную метку
  BACKUP_FILE="alfresco_back_${TIMESTAMP}.zip"  
  sudo zip -r -9 $TARGET_FOLDER/$BACKUP_FILE $FOLDER >/dev/null 2>&1
  
  # Проверка наличия созданного бэкапа
  if [ -f "$TARGET_FOLDER/$BACKUP_FILE" ]; then
    echo "BACKUP SUCCESSFUL!"    
    SUCCESS=1
  else
    echo "BACKUP Error!!"
  fi

echo "$(date +%d.%m.%Y) ($(date +%H.%M:%S)) # End backup."  
echo "...................................................." 

#------------------------------------------
# 4 - Start the Alfresco service
#------------------------------------------

  al_start
  echo "...................................................." 
  echo "$(date +%d.%m.%Y) ($(date +%H.%M:%S)) # Started Alfresco."    
  
#------------------------------------------
# 5 - Moved backup to a remote folder
#------------------------------------------  
  
  sudo mv $TARGET_FOLDER/$BACKUP_FILE $FOLDER_Remote
  # Проверка наличия созданного бэкапа
  if [ -f "$FOLDER_Remote/$BACKUP_FILE" ]; then
    echo "BACKUP Moved SUCCESSFUL!"    
    SUCCESS=1
  else
    echo "BACKUP Moved Error!!"
	SUCCESS=0
  fi
  
  echo "...................................................." 
  echo "$(date +%d.%m.%Y) ($(date +%H.%M:%S)) # Backup is moved to a remote location."  
  
#------------------------------------------
# 6 - Remove backups older than DUMP_NUM days
#------------------------------------------

  # выполняется поиск всех файлов старше DUMP_NUM дней 
  # в каталоге /opt/BackUps/ и выполняется их удаление
  if [ "$SUCCESS" = 1 ]; then
	sudo find $FOLDER_Remote -type f -mtime +$DUMP_NUM -exec rm {} \;
  fi

echo "$(date +%d.%m.%Y) ($(date +%H.%M:%S)) # The script is completed."
echo "...................................................." 