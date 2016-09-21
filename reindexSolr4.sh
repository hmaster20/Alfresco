#!/bin/bash
# Reindex Solr of Alfresco
# sudo sh ./reindexSolr4.sh 

echo "####################" 
echo "#   Reindex Solr   #" 
echo "####################" 

echo "$(date +%d.%m.%Y) ($(date +%H.%M:%S)) # Start script."
echo "...................................................." 

# Configuration:
  AL_FOLDER="/opt/alfresco-5.0.d"		# Расположение Alfresco
  
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

#----------------------------------------
# 1 - Begin by stopping Alfresco
#----------------------------------------
  
  al_stop
  echo "$(date +%d.%m.%Y) ($(date +%H.%M:%S)) # Alfresco SERVER stop."
  echo "...................................................." 

#------------------------------------------
# 2 - Delete the contents of the index data directories
#------------------------------------------

sudo rm -r /opt/alfresco-5.0.d/alf_data/solr4/index/archive/SpacesStore/*
echo "Deleted archive index...." 
sudo rm -r /opt/alfresco-5.0.d/alf_data/solr4/index/workspace/SpacesStore/*
echo "Deleted workspace index.." 
sudo rm -r /opt/alfresco-5.0.d/alf_data/solr4/model/*
echo "Deleted model index......" 
sudo rm -r /opt/alfresco-5.0.d/alf_data/solr4/content/*
echo "Deleted content index...." 

echo "$(date +%d.%m.%Y) ($(date +%H.%M:%S)) # Temporary files and cache are removed."  

#------------------------------------------
# 3 - Start the Alfresco service
#------------------------------------------

  al_start
  echo "...................................................." 
  echo "$(date +%d.%m.%Y) ($(date +%H.%M:%S)) # Started Alfresco. The script is completed." 
  echo "...................................................." 
