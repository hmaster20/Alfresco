#!/bin/bash
# Update of Alfresco
# sudo sh ./update.sh 

echo "#####################" 
echo "#  Update Alfresco  #" 
echo "#####################" 

echo "$(date +%d.%m.%Y) ($(date +%H.%M:%S)) # Start script."

# Configuration:
  FOLDER="/opt/alfresco-5.0.d"			# Расположение Alfresco
  FOLDER_update="/var/lib/jenkins/workspace/FPI/build/target/"
  FOLDER_current=$PWD
  result_ok="BUILD SUCCESSFUL"


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

# Function - Update Alfresco
al_update()
{
  #если файл существует, то выполним обновление
  if [ -f $FOLDER_update/install-amp.xml ]
    then
        sudo ant -Dalfresco.install=$FOLDER -f install-amp.xml > $FOLDER_current/update.log
  fi  
  
  # Опция "-q" заставляет команду grep подавить вывод.
  if cat $FOLDER_current/update.log | grep -q "$result_ok"
    then
	    echo "Update is installed successfully!"
		#rm $FOLDER_current/update.log
	else
        echo "Error!!. See the event log: update.log"
  fi
}


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
sudo rm -r /opt/alfresco-5.0.d/tomcat/logs/*
sudo rm -r /opt/alfresco-5.0.d/tomcat/work/*
sudo rm -r /opt/alfresco-5.0.d/tomcat/temp/*
sudo rm -r /opt/alfresco-5.0.d/tomcat/webapps/*.bak
# Removal of the cached data (удаление кэша):
sudo rm -r /opt/alfresco-5.0.d/tomcat/webapps/alfresco/
sudo rm -r /opt/alfresco-5.0.d/tomcat/webapps/share/
sudo rm -r /opt/alfresco-5.0.d/tomcat/webapps/solr4/

echo "$(date +%d.%m.%Y) ($(date +%H.%M:%S)) # Temporary files and cache are removed."  

#------------------------------------------
# 3 - Update
#------------------------------------------

echo "...................................................." 
echo "$(date +%d.%m.%Y) ($(date +%H.%M:%S)) # Start update."  

(cd $FOLDER_update && al_update) # directory changed in the subshell
# parent shell
echo "$(date +%d.%m.%Y) ($(date +%H.%M:%S)) # End update."  
echo "...................................................." 

#------------------------------------------
# 4 - Start the Alfresco service
#------------------------------------------

  al_start
  echo "...................................................." 
  echo "$(date +%d.%m.%Y) ($(date +%H.%M:%S)) # Started Alfresco. The script is completed." 
  echo "...................................................." 