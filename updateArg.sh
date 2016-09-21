#!/bin/bash
# Update of Alfresco
# sudo chmod +x updateArg.sh
# sudo sh ./updateArg.sh 

echo "#####################" 
echo "#  Update Alfresco  #" 
echo "#####################" 

# Configuration:
  FOLDER="/opt/alfresco-5.0.d"				# Расположение Alfresco
  FOLDER_update="/home/kravetsma/distr/"	# Расположение билдов
  FOLDER_current=$PWD
  result_ok="BUILD SUCCESSFUL"
  

# Проверка наличия параметра запуска
if [ -z "$1" ]
  then
	  echo "Do not Set option. Run the script is not possible!"
	  exit 1
  else
	  # Проверка существования папки
	  if [ -d "$FOLDER_update$1" ]; then
	  	  cd $FOLDER_update$1
 		  echo "For the installation will be used catalog \"$FOLDER_update$1!\"" 
	  else
	      echo "Directory \"$1\" in $FOLDER_update does not exist!"
		  exit 1
	  fi
fi


echo "$(date +%d.%m.%Y) ($(date +%H.%M:%S)) # Start script."
  
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
# Проверка существования папки
if [ -d "$FOLDER_update$1" ]; then
   # Проверка существования инсталятора
   if [ -f $FOLDER_update$1/install-amp.xml ]
      then
	  	  cd $FOLDER_update$1
          sudo ant -Dalfresco.install=$FOLDER -f install-amp.xml > $FOLDER_current/update.log
	  else
	  	  echo "File \"install-amp.xml\" in \"$FOLDER_update$1\" does not exist!"		 
   fi  
   # Проверка корректности обновления
   if cat $FOLDER_current/update.log | grep -q "$result_ok"
     then
	     cd $FOLDER_update
		 sudo cp yui-common* /opt/alfresco-5.0.d/tomcat/webapps/share/js/
		 sudo cp MessagesWebScript.class /opt/alfresco-5.0.d/tomcat/webapps/share/WEB-INF/classes/org/alfresco/web/scripts/		 
	     echo "Update is installed successfully!"
		 echo "Click the link /share/page/index and and press Refresh Web Scripts !!!"
	 else
         echo "Error!!. See the event log: update.log"
   fi
else
   echo "Не верно указан каталог сборки!"
   exit 1
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

(al_update)

echo "$(date +%d.%m.%Y) ($(date +%H.%M:%S)) # End update."  
echo "...................................................." 

#------------------------------------------
# 4 - Start the Alfresco service
#------------------------------------------

  al_start
  echo "...................................................." 
  echo "$(date +%d.%m.%Y) ($(date +%H.%M:%S)) # Started Alfresco. The script is completed." 
  echo "...................................................." 