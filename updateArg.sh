#!/bin/bash
# Update of Alfresco
# sudo chmod +x updateArg.sh
# sudo sh ./updateArg.sh 

echo "#####################" 
echo "#  Update Alfresco  #" 
echo "#####################" 

# Configuration:
  FOLDER="/opt/alfresco-5.0.d"				# Расположение Alfresco
  FOLDER_update="/home/kravetsma/distr/"	# Расположение билда
  FOLDER_current=$PWD						# Текущий рабочий каталог
  result_ok="BUILD SUCCESSFUL"				# Результат успешного обновления
  Time=0									# Текущее время, сек
  TimeWait=5								# Интервалы проверки, сек
  TimeWaitmax=240							# Максимальное время ожидания, сек
  PathBuild=""								# Переменная для хранения пути к сборке
  
  NORMAL='\033[0m'							#  ${NORMAL}  # все атрибуты по умолчанию
  LCYAN='\033[1;36m'     					#  ${LCYAN}
  LYELLOW='\033[1;33m'     					#  ${LYELLOW}
  REDWHITE='\033[37;1;41m'					#  ${REDWHITE}
  LGREEN='\033[1;32m'     					#  ${LGREEN}

# Проверка наличия параметра запуска
if [ -z "$1" ]
  then
      echo "\n${REDWHITE} Do not Set option. Run the script is not possible! ${NORMAL}"
      echo "${REDWHITE} ${NORMAL} Example:                                         ${REDWHITE} ${NORMAL}"
      echo "${REDWHITE} ${NORMAL}${LCYAN}         sudo sh ./updateArg.sh ${LYELLOW}v9x               ${NORMAL}${REDWHITE} ${NORMAL}"
      echo "${REDWHITE}                                                    ${NORMAL}"  
	  exit 1
  else
	  # Проверка существования папки
	  if [ -d "$FOLDER_update$1" ]; then
	  	  PathBuild=$FOLDER_update$1
 		  echo "For the installation will be used catalog \"$PathBuild\""
	  else
	      echo "Directory \"$1\" in $FOLDER_update does not exist!"
		  exit 1
	  fi
fi

# Фактический запуск скрипта
echo "...................................................." 
echo "$(date +%d.%m.%Y) ($(date +%H.%M:%S)) # Start script."
  
# Функция - Остановки Alfresco
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

# Функция - Запуска Alfresco
al_start()
{
  sudo service alfresco start
}

# Функция - обновления Alfresco из полученной сборки
al_update()
{
if [ -d "$PathBuild" ]; then						# Проверка существования папки
   if [ -f "$PathBuild/install-amp.xml" ]; then		# Проверка существования инсталятора    
	  	  cd $PathBuild
          sudo ant -Dalfresco.install=$FOLDER -f install-amp.xml > $FOLDER_current/update.log
		  if cat $FOLDER_current/update.log | grep -q "$result_ok"	# Проверка корректности обновления
             then
	             echo "${LGREEN}Build is installed successfully!${NORMAL}"
	      else
                 echo "${REDWHITE}Error!!. See the event log: $FOLDER_current/update.log${NORMAL}"
				 exit 1
          fi
	  else
	  	  echo "File \"install-amp.xml\" in \"$PathBuild\" does not exist!"		 
   fi
else
   echo "${REDWHITE}Не верно указан каталог сборки!${NORMAL}"
   exit 1
fi
}

# Функция - Таймер
timer()
{
	Time=$(($Time+$1)) # сумма значения + аргумент (входное значение)
    if [ "$Time" -ge "$TimeWaitmax" ]; then echo "Files are not updated. Timeout!"; exit 1;fi
}

# Функция - обновления Alfresco из полученных файлов
al_file_update()
{
folder1="/opt/alfresco-5.0.d/tomcat/webapps/share/js/"
folder2="/opt/alfresco-5.0.d/tomcat/webapps/share/WEB-INF/classes/org/alfresco/web/scripts/"

while [ ! -d $folder1 ] || [ ! -d $folder2 ]
do
  sleep $TimeWait #Задержка в секундах до выполнения следующей команды
  timer $TimeWait
done

if [ -d "$folder1" ] || [ -d "$folder2" ]; then
  cd $FOLDER_update
  sudo cp yui-common* $folder1
  sudo cp MessagesWebScript.class $folder2	
  echo "Files updated. Click the link ${LYELLOW}/share/page/index${NORMAL} and and press \"Refresh Web Scripts\" !!!"		 
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
# 3 - Build update
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
  echo "$(date +%d.%m.%Y) ($(date +%H.%M:%S)) # Started Alfresco." 
  echo "...................................................." 
  
#------------------------------------------
# 5 - Files update
#------------------------------------------

  al_file_update		 # Обновление файлов возможно только после полного запуска сервера
  echo "...................................................." 
  echo "$(date +%d.%m.%Y) ($(date +%H.%M:%S)) # The script is completed." 
  echo "...................................................."   
  