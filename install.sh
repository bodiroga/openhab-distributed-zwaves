#!/bin/bash

## Global variables
addons_dir="/usr/share/openhab/addons"
habmin_dir="/usr/share/openhab/webapps/habmin"
webapps_dir="/usr/share/openhab/webapps"
slash="/"

## Make sure only root can run our script
if [[ $EUID -ne 0 ]]; then
   echo -e "This script must be run as root" 1>&2
   exit 1
fi

## Check if addons and habmin folders exist
if [ ! -d "$addons_dir" ]; then
    echo -e "The $addons_dir does not exist"
    exit 1
fi
if [ ! -d "$habmin_dir" ]; then
    echo -e "The $habmin_dir does not exist"
    exit 1
fi



## Ask for the number of Z-Wave bindings to install and check if the answer is valid
re='^[0-9]+$'
echo -e "How many Z-wave bindings are you going to use? "
read n_bindings;
if ! [[ $n_bindings =~ $re ]]; then
	echo -e "\nYou need to specify a number"
        exit
fi

if [[ $n_bindings -gt 1 ]] && [[ 9 -gt $n_bindings ]]; then
	echo -e "\nOk, you are about to install \"$n_bindings\" Z-Wave bindings"
else
	echo -e "\nYou need to specify a number between 2 and 8"
        exit
fi


## Installing the required programs
echo -e '\nInstalling the required programs...'
apt-get --assume-yes install git unzip


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


## Get the new HABmin file path
search_start='*zwave'
search_end='*'
habmin_word="habmin"
habmin_search="$search_start$n_bindings$search_end"

new_habmin_file=$(find $current_folder$slash$habmin_word -name $habmin_search)

echo -e "\n\nHABmin to install:"
echo $new_habmin_file


## Get the old HABmin file path
habmin_search="*habmin*"
old_habmin_file=$(find $addons_dir -name "$habmin_search")

echo -e "\n\nHABmin to delete:"
echo $old_habmin_file


## Get the new Z-Wave bindings files paths
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

## Get the old Z-Wave bindings files paths
zwaves_to_delete=()
for (( i=2; i<=$n_bindings; i++ ))
do
	zwave_search="$search_start$i$search_end"
        zwave_file=$(find $addons_dir -name "$zwave_search")
        zwaves_to_delete+=($zwave_file)
done

echo -e "\n\nZWaves to delete:"
echo ${zwaves_to_delete[@]}




echo -e 'Deleting the old HABmin addon...'
#rm $old_habmin_file

echo -e 'Adding the new HABmin addon...'
#cp $new_habmin_file $addons_dir

echo -e 'Deleting the old Z-Wave bindings...'


echo -e 'Adding the new Z-Wave bindings...'


echo -e "Unziping and copying the HABmin folder..."
echo $(pwd)
cd habmin
echo $(pwd)
zip_file="habmin (unzip in the webapps folder).zip"
unzip $zip_file
cp habmin $webapps_dir
rm -r habmin
cd ..

echo -e '\nRemoving the tmp folder...'
#rm -rf /tmp/openhab-distributed-zwaves
