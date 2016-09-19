#!/bin/bash
# Backup of Alfresco

echo "#####################" 
echo "#  BackUp Alfresco  #" 
echo "#####################" 

echo "Start script - $(date +%d.%m.%Y) ($(date +%H.%M:%S))"


# Configuration:
  TIMESTAMP=$( date +%Y%m%d%H%M%S )		# Создание временной метки
  DUMP_NUM=7							# Число бэкапов
  FOLDER="/opt/alfresco-5.0.d"			# Расположение Alfresco


# Function - Stop Alfresco
al_stop()
{
  sudo service alfresco stop


  # Если Alfresco не останавливается, завершить работу скрипта, 
  # чтобы не повредить индексы данных !
  if [ "$?" != "0" ]; then
    echo "Alfresco Stop FAILED - STOP SCRIPT!"
    exit 1;
  fi
}

# Function - Start Alfresco
al_start()
{
  sudo service alfresco start
}

# Проверка наличия аргумента в командной строке запуска скрипта
if [ -d "$1" ]; then
  # Если указана папка, то сохранять в нее
  TARGET_FOLDER="$1"
else
  # Если не указана, то сохранять в папку по умолчанию
  TARGET_FOLDER="/opt/BackUps"
fi


#----------------------------------------
# 1 - Begin by stopping Alfresco
#----------------------------------------

  al_stop
  echo "Alfresco SERVER stop - $(date +%d.%m.%Y) ($(date +%H.%M:%S))"
  echo "...................................................." 
  
#----------------------------------------
# 2 - Deleting temps folders
#----------------------------------------  

echo "Delete temporary files..."
sudo rm -r /opt/alfresco-5.0.d/alfresco.log*
sudo rm -r /opt/alfresco-5.0.d/share.log*
sudo rm -r /opt/alfresco-5.0.d/solr.log*
sudo rm -r /opt/alfresco-5.0.d/postgresql/postgresql.log*
sudo rm -r /opt/alfresco-5.0.d/tomcat/logs/*
sudo rm -r /opt/alfresco-5.0.d/tomcat/work/*
sudo rm -r /opt/alfresco-5.0.d/tomcat/temp/*
sudo rm -r /opt/alfresco-5.0.d/tomcat/webapps/*.log
sudo rm -r /opt/alfresco-5.0.d/tomcat/webapps/*.bak


echo "Removal of the cached data..."

sudo rm -r /opt/alfresco-5.0.d/tomcat/webapps/alfresco/
sudo rm -r /opt/alfresco-5.0.d/tomcat/webapps/share/
sudo rm -r /opt/alfresco-5.0.d/tomcat/webapps/solr4/



echo "Temporary files and cache are removed - $(date +%d.%m.%Y) ($(date +%H.%M:%S))"  

#------------------------------------------
# 3 - Create backup
#------------------------------------------

echo "...................................................." 
echo "Start backup - $(date +%d.%m.%Y) ($(date +%H.%M:%S))"  

  # Create a backup filename with timestamp
  #BACKUP_FILE="alfresco_back_${TIMESTAMP}.tar"
  BACKUP_FILE="alfresco_back_${TIMESTAMP}.zip"
  #BACKUP_FILE="alfresco_back_${TIMESTAMP}.7z"
  
  #sudo tar zcf $TARGET_FOLDER/$BACKUP_FILE $AL_FOLDER  
  sudo zip -r -9 $TARGET_FOLDER/$BACKUP_FILE $FOLDER >/dev/null 2>&1
  #sudo 7z a $TARGET_FOLDER/$BACKUP_FILE $FOLDER  
  
  # Проверка наличия созданного бэкапа
  if [ -f "$TARGET_FOLDER/$BACKUP_FILE" ]; then
    echo "BACKUP SUCCESSFUL"    
    SUCCESS=1
  else
    echo "BACKUP Error!"
  fi

echo "End backup - $(date +%d.%m.%Y) ($(date +%H.%M:%S))"  
echo "...................................................." 

#------------------------------------------
# 4 - Start the Alfresco service
#------------------------------------------

  al_start
  echo "Alfresco service started."

echo "Started Alfresco - $(date +%d.%m.%Y) ($(date +%H.%M:%S))"    
#------------------------------------------
# 5 - Remove backups older than DUMP_NUM days
#------------------------------------------

  if [ "$SUCCESS" = 1 ]; then
	sudo find /opt/BackUps/ -type f -mtime +7 -exec rm {} \;
  fi

echo "Stop script - $(date +%d.%m.%Y) ($(date +%H.%M:%S))"