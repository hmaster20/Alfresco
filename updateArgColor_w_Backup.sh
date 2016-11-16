#!/bin/bash
# Update of Alfresco with Backup


  # Основные параметры:
  FOLDER="/opt/alfresco-5.0.d"				# Расположение Alfresco
  FOLDER_update="/home/kravetsma/distr/"	# Расположение билда
  FOLDER_current=$PWD						# Текущий рабочий каталог
  result_ok="BUILD SUCCESSFUL"				# Результат успешного обновления
  Time=0									# Текущее время, сек
  TimeWait=5								# Интервалы проверки, сек
  TimeWaitmax=240							# Максимальное время ожидания, сек
  PathBuild=""								# Переменная для хранения пути к сборке
  
  # Параметры бэкапа:
  Z=zip										# Архиватор
  TIMESTAMP=$( date +%Y%m%d%H%M%S )			# Создание временной метки
  DUMP_NUM=8								# Число бэкапов
  FOLDER_Backup="/opt/BackUps"				# Расположение бэкапов
  FOLDER_Remote="/mnt/BackupSrv/Backup"		# Расположение удаленного хранилища
  TARGET_FOLDER=$FOLDER_Backup
  
  # Цветовая маска:
  NORMAL='\033[0m'							#  ${NORMAL}
  GRAY='\033[0;37m'       					#  ${GRAY}      # серый (стандартный цвет)
  #DGRAY='\033[0;30m'	       				#  ${DRAY}      # темно-серый
  REDWHITE='\033[37;1;41m'					#  ${REDWHITE}  # белый на красном фоне
  DGRAY='\033[1;30m'						#  ${DGRAY}		# жирный серый
  LCYAN='\033[1;36m'     					#  ${LCYAN}		# жирный цвет морской волны
  LYELLOW='\033[1;33m'     					#  ${LYELLOW}	# жирный желтый
  LGREEN='\033[1;32m'     					#  ${LGREEN}	# жирный зеленый



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
 		  echo "\n${DGRAY}For the installation will be used catalog \"$PathBuild\"${NORMAL}\n"
	  else
	      echo "\nDirectory ${LYELLOW}\"$1\"${NORMAL} in $FOLDER_update ${LYELLOW}does not exist!${NORMAL}"
		  exit 1
	  fi
fi

# Фактический запуск скрипта
echo "${LGREEN}#####################"
echo "#  Update Alfresco  #"
echo "#####################${NORMAL}"
echo "...................................................." 
echo "$(date +%d.%m.%Y) ($(date +%H.%M:%S)) # Start script."
echo "...................................................." 
  
# Функция - Остановки Alfresco
al_stop()
{
  sudo service alfresco stop
  # Если Alfresco не останавливается, завершить работу скрипта, 
  # чтобы не повредить индексы данных !
  if [ "$?" != "0" ]; then
    echo "${REDWHITE}Alfresco FAILED - STOP SCRIPT!\n${NORMAL}"
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
	             echo "\n${LGREEN}Build is installed successfully!${NORMAL}\n"
	      else
                 echo "${REDWHITE}Error!! See the event log: $FOLDER_current/update.log${NORMAL}"
				 exit 1
          fi
	  else
	  	  echo "${REDWHITE}File \"install-amp.xml\" in \"$PathBuild\" does not exist!${NORMAL}"		 
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
  if [ -f "MessagesWebScript.class" ] && [ -f "yui-common.js" ] 
	then  
		sudo cp yui-common* $folder1
		sudo cp MessagesWebScript.class $folder2	
		echo "Files updated. Click the link ${LYELLOW}/share/page/index${NORMAL} and and press \"Refresh Web Scripts\" !!!"	
    else
		echo "${LYELLOW}Необходимые файлы отсутствуют!${NORMAL}"
  fi  
fi
}

# Функция - проверка наличия или установки пакета архивации
check_zip()
{
if [ $(dpkg-query -W -f='${Status}' $Z 2>/dev/null | grep -c "ok installed") -eq 0 ];
then
   echo "Пакет $Z не найден! Запущена процедура установки!"
   sudo apt-get install $Z
fi
}

# Функция - создания резервной копии Alfresco
al_file_backup()
{
  # Проверка наличия архиватора
  check_zip
  # Создание бэкапа с именем, содержащем временную метку
  BACKUP_FILE="alfresco_back_${TIMESTAMP}.zip"  
  sudo zip -r -9 $TARGET_FOLDER/$BACKUP_FILE $FOLDER >/dev/null 2>&1
  
  # Проверка наличия созданного бэкапа
  if [ -f "$TARGET_FOLDER/$BACKUP_FILE" ]; then
    echo "\n${LGREEN}BACKUP SUCCESSFUL!${NORMAL}\n"    
    SUCCESS=1
  else
    echo "${REDWHITE}BACKUP Error!!${NORMAL}"
	# в случае ошибки - заврешение работы скрипта
	# exit 1
  fi
}

# Функция - перемещения резервной копии Alfresco в хранилище
al_file_backup_moved()
{
  sudo mv $TARGET_FOLDER/$BACKUP_FILE $FOLDER_Remote
  # Проверка наличия созданного бэкапа
  if [ -f "$FOLDER_Remote/$BACKUP_FILE" ]; then
    echo "\n${LGREEN}BACKUP Moved SUCCESSFUL!${NORMAL}\n"    
    SUCCESS=1
  else
    echo "${REDWHITE}BACKUP Moved Error!!${NORMAL}"
	SUCCESS=0
  fi
}


#----------------------------------------
# 1 - Begin by stopping Alfresco
#----------------------------------------

  echo "${DGRAY}"
  al_stop
  echo "${NORMAL}"
  echo "$(date +%d.%m.%Y) ($(date +%H.%M:%S)) # Alfresco SERVER stop."
  echo "...................................................." 
  
#----------------------------------------
# 2 - Deleting temps folders
#----------------------------------------  

echo "${DGRAY}"
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
echo "${NORMAL}"

echo "$(date +%d.%m.%Y) ($(date +%H.%M:%S)) # Temporary files and cache are removed."  
echo "...................................................." 

#------------------------------------------
# 3 - Create backup
#------------------------------------------

 echo "\n$(date +%d.%m.%Y) ($(date +%H.%M:%S)) # Start backup."
 al_file_backup
 al_file_backup_moved
 echo "$(date +%d.%m.%Y) ($(date +%H.%M:%S)) # End backup."

#------------------------------------------
# 4 - Build update
#------------------------------------------

echo "...................................................." 
echo "$(date +%d.%m.%Y) ($(date +%H.%M:%S)) # Start update."  

(al_update)

echo "$(date +%d.%m.%Y) ($(date +%H.%M:%S)) # End update."  
echo "...................................................." 

#------------------------------------------
# 5 - Start the Alfresco service
#------------------------------------------

  echo "${DGRAY}"
  al_start
  echo "${NORMAL}"
  echo "...................................................." 
  echo "$(date +%d.%m.%Y) ($(date +%H.%M:%S)) # Started Alfresco." 
  echo "...................................................." 
  
#------------------------------------------
# 6 - Files update
#------------------------------------------

  al_file_update		 # Обновление файлов возможно только после полного запуска сервера
  echo "...................................................." 
  echo "$(date +%d.%m.%Y) ($(date +%H.%M:%S)) # The script is completed." 
  echo "...................................................."   
  