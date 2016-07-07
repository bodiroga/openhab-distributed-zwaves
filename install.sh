#!/bin/bash

## Global variables
addons_dir="/usr/share/openhab/addons"
habmin_dir="/usr/share/openhab/webapps/habmin"
webapps_dir="/usr/share/openhab/webapps"
logs_dir="/var/log/openhab"
slash="/"
min_n_bindings=2
max_n_bindings=8


## Making sure only root can run our script
if [[ $EUID -ne 0 ]]; then
   echo -e "This script must be run as root" 1>&2
   exit 1
fi


## Checking if addons and habmin folders exist
if [ ! -d "$addons_dir" ]; then
    echo -e "The $addons_dir does not exist"
    exit 1
fi
if [ ! -d "$habmin_dir" ]; then
    echo -e "The $habmin_dir does not exist"
    exit 1
fi


## Asking for the number of Z-Wave bindings to install and check if the answer is valid
echo -e "How many Z-wave bindings are you going to use? "
read n_bindings;
re='^[0-9]+$'
if ! [[ $n_bindings =~ $re ]]; then
	echo -e "\nYou need to specify a number"
        exit
fi

if [[ $n_bindings -ge $min_n_bindings ]] && [[ $max_n_bindings -ge $n_bindings ]]; then
	read -p "Ok, you are about to install \"$n_bindings\" Z-Wave bindings. Are you sure? (y/N)? " choice
	case "$choice" in 
	  y|Y ) echo -e "\nStarting the installation process";;
	  * ) echo -e "\nInstallation aborted"; exit;;
	esac
else
	echo -e "\nYou need to specify a number between $min_n_bindings and $max_n_bindings"
        exit
fi

## Installing the required programs
echo -e '\nInstalling the required programs...'
apt-get --assume-yes install git unzip >/dev/null


## Cloning the github repository
cd /tmp
repository_name="openhab-distributed-zwaves"
if [ -d "$repository_name" ]; then
	echo -e "\nThe github repository already exists, let's make a 'git pull'..."
	cd $repository_name
	git pull
else
	echo -e "\nCloning the github repository..."
	git clone https://github.com/bodiroga/openhab-distributed-zwaves.git
	cd $repository_name
fi
current_folder=$(pwd)


## Getting the new HABmin file path
search_start='*zwave'
search_end='*'
habmin_word="habmin"
habmin_search="$search_start$n_bindings$search_end"

new_habmin_file=$(find $current_folder$slash$habmin_word -name $habmin_search)

echo -e "\n\nHABmin to install:"
echo $new_habmin_file


## Getting the old HABmin file path
habmin_search="*habmin*"
old_habmin_file=$(find $addons_dir -name "$habmin_search")

echo -e "\n\nHABmin to delete:"
echo $old_habmin_file


## Getting the new Z-Wave bindings files paths
zwave_word="zwave"
zwaves_to_install=()
for (( i=2; i<=$n_bindings; i++ ))
do
	zwave_search="$search_start$i$search_end"
        zwave_file=$(find $current_folder$slash$zwave_word -name "$zwave_search")
        zwaves_to_install+=($zwave_file)
done

echo -e "\n\nZWaves to install:"
echo ${zwaves_to_install[@]}


## Getting the old Z-Wave bindings files paths
search_start='*.zwave'
zwaves_to_delete=()
for (( i=$min_n_bindings; i<=$max_n_bindings; i++ ))
do
	zwave_search="$search_start$i$search_end"
        zwave_file=$(find $addons_dir -name "$zwave_search")
        zwaves_to_delete+=($zwave_file)
done

echo -e "\n\nZWaves to delete:"
echo ${zwaves_to_delete[@]}


## Deleting the old HABmin addon
echo -e 'Deleting the old HABmin addon...'
rm $old_habmin_file


## Deleting the old Z-Wave bindings
echo -e 'Deleting the old Z-Wave bindings...'
for i in "${zwaves_to_delete[@]}"
do
	rm $i
done


## Adding the new HABmin addon
echo -e 'Adding the new HABmin addon...'
cp $new_habmin_file $addons_dir


## Adding the new Z-Wave bindings
echo -e 'Adding the new Z-Wave bindings...'
for i in "${zwaves_to_install[@]}"
do
	cp $i $addons_dir
done


## Unziping and copying the HABmin folder
echo -e "Unziping and copying the HABmin folder..."
cd habmin
zip_file="habmin.zip"
unzip $zip_file > /dev/null
cp -r habmin $webapps_dir
rm -r habmin
cd ..


## Removing the git repository
read -p "Do you want to remove the git repository from your computer (y/N)? " choice
case "$choice" in 
  y|Y ) echo -e "Deleting the git repository..."; rm -rf /tmp/openhab-distributed-zwavesd;;
  * ) echo -e "Keeping the git repository...";;
esac


## Restarting openHAB
echo -e "\nRestarting openHAB..."
read -p "Do you want to delete old openHAB log files (y/N)? " choice
case "$choice" in 
  y|Y ) echo -e "Deleting old log files..."; rm $logs_dir$slash$search_end;;
  * ) echo -e "Keeping old log files...";;
esac
/etc/init.d/openhab restart > /dev/null

echo -e "\Done."
