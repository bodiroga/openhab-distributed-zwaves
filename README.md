## Introduction

This script installs and configures the openHAB part of a distributed Z-Wave network. It installs the neccesary Z-Wave bindings, updates the io.habmin.jar file accordingly and add the needed javascript files to the HABmin web interface.

## Installation

You don't even need to clone the repository to use this script, just download the install.sh file to your server, execute it with root privileges, select the number of Z-Wave networks that will be available in your installation and the script will take care of the rest.

wget https://raw.githubusercontent.com/bodiroga/openhab-distributed-zwaves/master/install.sh

sudo chmod +x install.sh

sudo ./install.sh
