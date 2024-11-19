#!/bin/bash

# http://www.patorjk.com/software/taag/#p=display&c=echo&f=Rectangles&t=TrueNAS%20SCALE
#  _____             _____ _____ _____    _____ _____ _____ __    _____ 
# |_   _|___ _ _ ___|   | |  _  |   __|  |   __|     |  _  |  |  |   __|
#   | | |  _| | | -_| | | |     |__   |  |__   |   --|     |  |__|   __|
#   |_| |_| |___|___|_|___|__|__|_____|  |_____|_____|__|__|_____|_____|
#                                                                      
# TrueNAS SCALE Helper by Daniel Ketel, 2024
# For latest version visit https://github.com/kage-chan/TNSH
# TrueNAS® is a registered Trademark of IXsystems, Inc.
#

# Settings that are user-editable
debug=false;

# Global variables
version="0.8"
initExists=false
initScript=""
initScriptId=0
configPower=false
newPartition=""

NO_FORMAT="\033[0m"
F_BOLD="\033[1m"
C_LIME="\033[48;5;10m"
C_GREY0="\033[38;5;16m"
C_GOLD1="\033[38;5;220m"
C_DODGERBLUE1="\033[38;5;33m"
C_WHITE="\033[38;5;15m"
C_RED="\033[48;5;9m"


printHeader () {
	echo "                                                                      ";
	echo " _____             _____ _____ _____    _____ _____ _____ __    _____ ";
	echo "|_   _|___ _ _ ___|   | |  _  |   __|  |   __|     |  _  |  |  |   __|";
	echo "  | | |  _| | | -_| | | |     |__   |  |__   |   --|     |  |__|   __|";
	echo "  |_| |_| |___|___|_|___|__|__|_____|  |_____|_____|__|__|_____|_____|";
	echo "                                                                      ";
	echo "                               Helper  v"$version"                           ";
	echo "";
	echo " 2024, Daniel Ketel. For latest version visit ";
	echo " https://github.com/kage-chan/TNSH";
	echo "";
	
	if $initExists ; then
		echo ""
		echo -e "  ${F_BOLD}${C_GREY0}${C_LIME}Init script found at:${NO_FORMAT}" $initScript
		echo -n "  Configured: "
		if $configPower ; then
			echo -n -e "${F_BOLD}${C_GOLD1}Power${NO_FORMAT}"
		fi
	fi
}

#------------------------------------------------------------------------------
# name: mainMenu
# args: none
# Shows main menu and lets user choose what to do
#------------------------------------------------------------------------------
mainMenu () {
	clear
	echo "";
	
	printHeader
	
	echo "";
	echo "  Press p to show post-install menu";
	echo "  Press 1 to optimize power settings";
	echo "  Press 2 to install HomeAssistant OS in a VM";
	echo "  Press 0 to remove init script and revert changes";
	echo "  Press r to recover previous install";
	echo "  Press m to move the init script location";
	echo "  Press q to quit";
	echo ""
	# Let user choose menu entry.
	while true; do
		read -n 1 -p "  Input Selection:  " mainMenuInput
		case $mainMenuInput in
		[0]*)
			removeInitScript
			break
			;;
		[1]*)
			optimizePower
			break
			;;
		[2]*)
			installHAOS
			break
			;;
		[mM]*)
			moveInitScript
			break
			;;
		[pP]*)
			postInstall
			break
			;;
		[rR]*)
			recoverInstall
			break
			;;
		[qQ]*)
			echo "";
			echo "";
			exit;
			;;
		*)
			echo "";
			echo "  Invalid selection. Please select one of the above options.";
			echo "";
		esac
	done	
}

#------------------------------------------------------------------------------
# name: postinstall
# args: none
# Shows post-install menu and lets user choose what to do
#------------------------------------------------------------------------------
postInstall () {
	clear
	echo ""
	echo "  Post-install Menu"
	echo ""
	echo -e "  ${F_BOLD}${C_WHITE}${C_RED}!!! DANGER ZONE !!!${NO_FORMAT}"
	echo "  Executing these options is meant to be done right after the installation."
	echo "  They might break your system if used on a non-clean install."
	echo "  Proceed on your own risk!"
	echo ""
	echo "  Press 1 to fill up system drive with new parititon"
	echo "  Press 2 to make new partition available in zpool"
	echo "  Press q to return to main menu"
	echo ""
	
	while true; do
		read -n 1 -p "  Input Selection:  " postInstallInput
		
		case $postInstallInput in
		[1]*)
			fillSysDrive
			break
			;;
		[2]*)
			makeAvailableZpool
			break
			;;
		[qQ]*)
			mainMenu
			break
			;;
		*)
			echo ""
			echo "  Invalid selection. Please select one of the above options."
			echo ""
			continue
		esac
	done
}

#------------------------------------------------------------------------------
# name: installModeMenu
# args: none
# Modifies the TrueNAS SCALE installer, user can choose partition size
#------------------------------------------------------------------------------
installModeMenu () {
	clear
	echo "";
	
	printHeader
	
	echo "";
	echo "  ---=== INSTALL MODE ===---";
	echo "  In install mode this script offers only one function:";
	echo "  Install TrueNAS SCALE on a partition rather than the whole disk.";
	echo "";
	echo "  Please choose the size of the system partition";
	echo "";
	echo "  1.  16 GB  (is enough, might get tight at some point)";
	echo "  2.  32 GB  (generally recommended)";
	echo "  3.  64 GB  (to be on the safe side, if you have some disk space to spare)";
	echo "  Press q to quit";
	echo "";
	
	size="";
	
	# Let user choose partition size
	while true; do
		read -n 1 -p "  Input Selection:  " installInput
		
		case $installInput in
		[1]*)
			size="16G"
			break
			;;
		[2]*)
			size="32G"
			break
			;;
		[3]*)
			size="64G"
			break
			;;
		[qQ]*)
			exit;
			;;
		*)
			echo ""
			echo "  Invalid selection. Please select one of the above options."
			echo ""
			continue
		esac
	done
	
	sed -i 's/sgdisk -n3:0:0/sgdisk -n3:0:+'$size'/g' /usr/sbin/truenas-install /usr/sbin/truenas-install
	/usr/sbin/truenas-install
	exit
}

#------------------------------------------------------------------------------
# name: optimizePower
# args: none
# Shows post-install menu and lets user choose what to do
#------------------------------------------------------------------------------
optimizePower () {
	echo "";
	echo "  Checking if PCIE ASPM is enabled..."
	if [ $(dmesg | grep "OS supports" | grep ASPM | wc -l) -ge 1 ] ; then
		echo "  PCIE ASPM supported by os and active. Activating powersave modes."
	else
		echo ""
		echo "  No PCIE ASPM detected"
		echo "  If hardware supports ASPM, please check BIOS if ASPM is to be handled by OS or BIOS. If \"Auto\" setting exists, force ASPM to be handled by OS. You may also try using the4 pcie_aspm=force kernel parameter. Before doing so, please ensure that all your PCIe devices do support ASPM, otherwise forcing the kernel to enable ASPM might result in an unstable system."
	fi
	
	powertop --auto-tune -q >> /dev/null
	echo "powersave" > /sys/module/pcie_aspm/parameters/policy
	
	while true; do
		echo "  Power usage optimized. May take a minute to settle in. Please check power usage if available";
		echo "";
		read -n 1 -p "  Do you want these settings to be made permanent? [Y/n]  " keepChanges
		
		case $keepChanges in
		''|[yY]*)
			# Create RC script
			buildInitScript POWER
			echo "  Changes made permanent"
			break
			;;
		[nN]*)
			echo "";
			echo "  Resetting PCIe ASPM mode to default. To fully revert to default power management, please reboot";
			echo default > /sys/module/pcie_aspm/parameters/policy
			break
			;;
		*)
			echo ""
			echo "  Invalid selection. Please select yes or no."
			continue
		esac
	done
	
	read -n 1 -p "  Press any key to return to the main menu"
	mainMenu
}


#------------------------------------------------------------------------------
# name: installHAOS
# args: none
# Create a new VM and installs the latest stable version of HAOS inside
#------------------------------------------------------------------------------
installHAOS () {
	# Get current HAOS version
	echo "  Fetching current HAOS image"
	version=$(curl -s https://raw.githubusercontent.com/home-assistant/version/master/stable.json | grep "ova" | cut -d '"' -f 4)
	URL="https://github.com/home-assistant/operating-system/releases/download/"$version"/haos_ova-"$version".qcow2.xz"
	
	# Create a temporary working directory
	mkdir -p /mnt/services/HAOS
	cd /mnt/services/HAOS
	
	# Get HAOS image
	wget $URL
	
	# TrueNAS SCALE's VMs use zvols. Convert the qcow image to a raw disk image. Conveniently zvol can be accessed as file :)
	echo -n "  Extracting image. "
	unxz haos_ova-$version.qcow2.xz
	zfs create -s -V 32GB services/tnsh_haos
	echo "Done."
	# Sleep needed at this point, due to zvol creation taking some time
	# and image conversion will fail due to missing destination otherwise
	sleep 1
	echo -n "  Writing image to disk. "
	qemu-img convert -f qcow2 -O raw haos_ova-$version.qcow2 /dev/zvol/services/tnsh_haos
	echo "Done."
	
	echo "  Creating VM and attaching devices"
	cli -c "service vm create name=\"TNSH_HAOS\" memory=2048"
	# Get ID of new VM
	query=$(cli -c "service vm query" | grep TNSH_HAOS)

	j=1;
    if [ ${#query} -eq 0 ] ; then
        if $debug ; then
                echo "  No virtual machines found."
        fi
    else
        if $debug ; then
                echo "  Virtual machine found. Fetching data. "
        fi

        initExists=true

        for i in $query ; do
                if [ $j -eq 2 ] ; then
                        if $debug ; then
                                echo "  VM's ID is:" $i;
                        fi

                        vmid=$i
                fi
                j=$((j+1))
        done
    fi
	
	cli -c "service vm device create dtype=DISK vm="$vmid" attributes={\"type\":\"VIRTIO\",\"path\":\"/dev/zvol/services/tnsh_haos\"}"
	cli -c "service vm device create dtype=NIC vm="$vmid" attributes={\"type\":\"E1000\",\"nic_attach\":\"br0\"}"
	
	echo -n "  Cleaning up. "
	rm -rf /mnt/services/HAOS
	echo "Done."
	
	echo ""
	echo "  Successfully installed HAOS."
	sleep 3
}

#------------------------------------------------------------------------------
# name: fillSysDrive
# args: none
# Shows post-install menu and lets user choose what to do
#------------------------------------------------------------------------------
fillSysDrive () {
	echo ""
	echo "  Block devices detected:"
  
	# Get list of block devices and push into an array
	blks=$(lsblk -o NAME --path | grep "^[/]")
	devices=()
	j=1
	echo "";
	echo "  0.  Abort";
	while read -ra dev; do
		for i in "${dev[@]}"; do
			devices+=($i)
			echo "  "$j". " $i
			((j=j+1))
		done
	done <<< "$blks"
  
	# Show detected block devices and let user choose right one
	echo ""
	while true; do
		read -n 1 -p "  Select block device TrueNAS SCALE is installed on: [0-"$((j-1))"] " selectedDrive
		
		# Check if input is numeric
		re='^[0-9]'
		if ! [[ $selectedDrive =~ $re ]] ; then
			echo "";
			echo "  Error: Not a number. Please try again.";
			continue
		fi

		# Check if selection is higher than list length
		if [ "$selectedDrive" -gt "${#devices[@]}" ] ; then
			echo "  Error: Not a valid option"
			continue
		fi
		
		# Return to menu if user requested abort
		if [[ "$selectedDrive" == 0 ]]; then
			echo "";
			echo "  Aborted";
			read -p "  Press Enter to return to post-install menu"
			postInstall
		fi
		
		break
	done
  
	# Get sector of current last physical partition's end and create new partition behind that
	device=${devices[(($selectedDrive-1))]}
	parts=$(parted $device unit s print free | grep Free | tail -1)
	read -ra strt <<< "$parts"
	start=${strt::-1}
	parted -s $device unit s mkpart services $start 100%

	# Show result to user and ask for confirmation
	echo "";
	echo "  Please check below if the partition \"services\" has been created successfully";
	echo "";
	parted -s $device unit GB print;

	while true; do
		read -n 1 -p "  Has the partition successfully been created? [y/n]  " confirmation
  
		case $confirmation in
		[yY]*)
			echo "";
			break
			;;
		[nN]*)
			echo "";
			echo "  Error: unable to create services partition. Exiting";
			exit
			;;
		*)
			echo "  Invalid choice. Please try again";
		esac
	done
	
	echo "";
	
	# Ask user if script should proceed and make created partition available to zpool
	numPartitions=0;
	while true; do
		read -n 1 -p "  Should the new partition be made available to zpool now? [y/n]  " dozpool
  
		case $dozpool in
		[yY]*)
			# Build string that contains device of the newly created partition
			numPartitions=$(lsblk -l -o NAME --path | grep "^$device" | tail -n +2 | wc -l)
			if [[ $device == /dev/nvme* ]] ; then
				newPartition=${device}p$numPartitions
			else
				newPartition=$device$numPartitions
			fi
			makeAvailableZpool
			break
			;;
		[nN]*)
			echo "";
			break
			;;
		*)
			echo "  Invalid choice. Please try again";
		esac
	done
}

#------------------------------------------------------------------------------
# name: makeAvailableZpool
# args: none
# Creates a zpool using the additional partition on the system disk and
# exports it, so it can be imported again from the UI
#------------------------------------------------------------------------------
makeAvailableZpool () {
	# Determine if partition has been created in previous step
	if [ "$newPartition" = "" ]; then
		# Let user choose device to use
		# Get list of block devices and push into an array
		blks=$(lsblk -o NAME --path  | grep "^[/]")
		devices=()
		j=1
		echo "";
		echo "  0.  Abort";
		while read -ra dev; do
			for i in "${dev[@]}"; do
			devices+=($i)
			echo "  "$j". " $i
			((j=j+1))
			done
		done <<< "$blks"
		
		echo ""
		while true; do
			read -n 1 -p "  Select block device to use: [0-"$((j-1))"] " selectedDev
		
			# Check if input is numeric
			re='^[0-9]'
			if ! [[ $selectedDev =~ $re ]] ; then
				echo "";
				echo "  Error: Not a number. Please try again.";
				continue
			fi

			# Check if selection is higher than list length
			if [ "$selectedDev" -gt "${#devices[@]}" ] ; then
				echo "  Error: Not a valid option"
				continue
			fi
		
			# Return to menu if user requested abort
			if [[ "$selectedDev" == 0 ]]; then
				echo "";
				echo "  Aborted";
				read -p "  Press Enter to return to post-install menu"
				postinstall
			fi
			
			break
		done
		
		device=${devices[$selectedDev-1]}
		
		# Let user choose partition to use
		# Discard first entry in list, because it will be the device itself
		parts=$(lsblk -l -o NAME --path  | grep "^$device" | tail -n +2)
		partitions=()
		j=1
		echo "";
		echo "  0.  Abort";
		while read -ra part; do
			for i in "${part[@]}"; do
			partitions+=($i)
			echo "  "$j". " $i
			((j=j+1))
			done
		done <<< "$parts"
		
		echo ""
		while true; do
			read -n 1 -p "  Select partition to use: [0-"$((j-1))"] " selectedPart
		
			# Check if input is numeric
			re='^[0-9]'
			if ! [[ $selectedPart =~ $re ]] ; then
				echo "";
				echo "  Error: Not a number. Please try again.";
				continue
			fi

			# Check if selection is higher than list length
			if [ "$selectedPart" -gt "${#partitions[@]}" ] ; then
				echo "  Error: Not a valid option"
				continue
			fi
		
			# Return to menu if user requested abort
			if [[ "$selectedPart" == 0 ]]; then
				echo "";
				echo "  Aborted";
				read -p "  Press Enter to return to post-install menu"
				postInstall
			fi
			
			break
		done
		
		if [[ $device == /dev/nvme* ]] ; then
			newPartition=${device}p$selectedPart
		else
			newPartition=$device$selectedPart
		fi
	fi
	
	if $debug ; then
		echo "";
		echo "  Partition to be used:" $newPartition;
	fi
	
	# Using the TrueNAS CLI here is not possible, since storage pool create does not support
	# creating pools with partitoins, but only whole devices.
	# The CLI command
	# cli -c "storage pool create name=\"services\" topology={\"data\":{\"type\":\"STRIPE\",\"disks\":[\"/dev/XXXX\"]}}"
	# cannot be used for this, since it will return with an error that the disk is already being used for the boot-pool.
	# Therefore a pool is manually created using the zpool tool and is then imported into TrueNAS using the CLI's storage pool import_pool
	zpool create -f services $newPartition
	zpool export services
	# To use import_pool, we need the guid of the pool, which can be found using the storage pool import_find command
	pool=$(cli -c "storage pool import_find" | grep services)
	poolGuid=0;
	
	if $debug ; then
		echo "  The following pool was found: ";
		echo $pool
	fi
	
	# Check if pool was correctly registered in the previous steps. If not, return to main menu
	if [ ${#pool} -eq 0 ] ; then
		echo "  Failed to create pool. Please check if partition used wass correct."
		read -p "  Press Enter to return to the main menu"
		mainMenu
	fi
	
	id=0
	j=0;
	for i in $pool ; do
		if [ $j -eq 3 ] ; then
			if $debug ; then
				echo "  GUID of pool is" $i". Importing now...";
			fi
			poolGuid=$i
		fi
		((j=j+1))
	done
	
	cli -c "storage pool import_pool pool_import={\"guid\":\""$poolGuid"\"}"
	
	echo "  Successfully created and exported zpool.";
	echo "  Please check the WebUI if the pool has successfully been imported.";
	
	echo ""
	read -p "  Press Enter to return to the post-install menu"
	postInstall
}

#------------------------------------------------------------------------------
# name: getInitScript
# args: none
# Gets the current path of the init script from the TrueNAS SCALE init system
# note: will store found ocnfig into global variable
#------------------------------------------------------------------------------
getInitScript () {
	# If init script has previously been created, it has been registered with
	# TrueNAS SCALE's init system. Do a quick query using the cli and check
	# Check for init script's location. Multiple localtions possible, ultimately ask user
	query=$(cli -c "system init_shutdown_script query" | grep tnsh)
			
	if $debug ; then
		echo "  Query returned the following entries: ";
		echo $query
	fi
	
	# Check if query contained entries
	j=1;
	if [ ${#query} -eq 0 ] ; then
		if $debug ; then
			echo "  Init script has not been registered with startup system in the past."
		fi
	else
		if $debug ; then
			echo "  Init script is registered. Fetching data. "
		fi
		
		initExists=true
		
		for i in $query ; do
			if [ $j -eq 2 ] ; then
				if $debug ; then
					echo "  Init script id is" $i;
				fi
				
				initScriptId=$i
			fi
		
			if [ $j -eq 7 ] ; then
				if $debug ; then
					echo "  Path to init script is" $i
				fi
				
				initScript=$i
				break
			fi
			j=$((j+1))
		done
	fi
}


#------------------------------------------------------------------------------
# name: readInitConfig
# args: none
# Gets the current path of the init script from the TrueNAS SCALE init system
# note: will store extracted config in global variables
#------------------------------------------------------------------------------
readInitConfig () {
	# If init script exists, find out current configuration
	if $initExists ; then		
		# Current configuration is coded into the third line of init script
		config=$(sed -n '3p' $initScript)
		if $debug ; then
			echo "Configuration is" $config
		fi
		
		for i in $config ; do
			if $debug ; then
				echo "Current i is:" $i
			fi
			case $i in
			[POWER]*)
				if $debug ; then
					echo "  Power configured in init script"
				fi
				configPower=true
				;;
			*)
			esac
		done
	fi
}


#------------------------------------------------------------------------------
# name: buildInitScript
# args: none
# Builds the init script, writes it and registers it with TrueNAS SCALES's
# init system so it will be called during boot
#------------------------------------------------------------------------------
buildInitScript () {
	choosePath=false;
	servicesExist=$(test -d /mnt/services);
	
	if ! $initExists ; then
		echo ""
		echo "  No previous init script detected.";
	
		if $servicesExist ; then
			echo "";
			echo "  Services partition detected. The default location for the init script is";
			echo "  /mnt/services/tnshInit.sh. It is recommended to use this location, since it will ensure";
			echo "  that the init script will also survive TrueNAS SCALE updates.";
			
			read -n 1 -p "  Do you want to place the script in this default location? [Y/n]  " defaultLocation
  
			case $defaultLocation in
			''|[yY]*)
				initScript=/mnt/services/tnshInit.sh
				;;
			[nN]*)
				choosePath=true
				;;
			*)
				echo "  Invalid choice. Please try again";
			esac
		fi
	
		if $choosePath ; then
			if  ! $servicesExist ; then
				echo "";
				echo "  No services partition detected in /mnt/services!";
			fi
			
			echo "";
			echo "  Please choose a path for the TrueNAS Scale Helper Script's init script.";
			echo "  Thew default location \"/etc/init.d/tnsh\" will be used if you leave the path empty.";
			echo -e "  ${F_BOLD}${C_WHITE}${C_RED}WARNING:${NO_FORMAT} In the default location the init script will likely be removed each time";
			echo "           you install an update for TrueNAS SCALE. Only paths on a different dataset";
			echo "           than the system will survive updates!";
			echo "";
			
			while true; do
				read -p "  Please specify desired directory for the init script: " pathForInitScript
			
				if [[ -z "$pathForInitScript" ]] ; then
					echo "";
					echo "  Using /etc/init.d/tnsh";
					echo "  It is very likely that the script will be removed by future TrueNAS SCALE updates.";
					echo "  Please be aware of this and periodically rerun this script after updating TrueNAS SCALE.";
					echo "";
					initScript=/etc/init.d/tnsh
					break
				fi
				
				if [[ ! -d "$pathForInitScript" ]] ; then
					echo "";
					echo "  Directory does not exist. Please specify an existing path.";
					echo "";
					continue
				fi
			
				if [[ $pathForInitScript != /* ]] ; then
					echo ""
					echo "  Please specify an absolute path!";
					echo ""
					continue
				fi
			
				if [[ $pathForInitScript != /mnt/* ]] ; then
					echo "";
					echo "  Path is not inside a different dataset.";
					echo "  It is very likely that the script will be removed by future TrueNAS SCALE updates.";
					echo "  Please be aware of this and periodically rerun this script after updating TrueNAS SCALE.";
					echo "";
				fi
				
				if [[ $pathForInitScript == */ ]] ; then
					initScript=$pathForInitScript"tnshInit.sh"
				else
					initScript=$pathForInitScript"/tnshInit.sh"
				fi
				break
			done
		fi
	fi
	
	# Check what is to be added
	case $1 in
	[POWER]*)
		configPower=true
		;;
	*)
	esac
	
	# Write file header including current config
	echo "#!/bin/bash" > $initScript;
	echo "# ! DO NOT EDIT THIS FILE !" >> $initScript;

	echo -n "#" >> $initScript;
	
	if $configPower == true ; then
		echo -n " POWER" >> $initScript;
	fi
	
	echo ""
	if $debug ; then
		echo "  Writing init script...";
	fi
	
	# Write file's description
	echo "" >> $initScript;
	echo "#" >> $initScript;
	# Make sure header is commented, otherwise script will be broken
	printHeader | sed 's/^/# /' >> $initScript
	echo ""  >> $initScript;
	echo "#  This is a supplement script to make the original script's settings   "  >> $initScript;
	echo "#  permanent and enable them at boot."  >> $initScript;
	echo ""  >> $initScript;
	
	
	# Actual init script starts here
	if $configPower == true ; then
		echo ""  >> $initScript;
		echo "# Powermanagement"  >> $initScript;
		echo "powertop --auto-tune"  >> $initScript;
		echo "echo powersave > /sys/module/pcie_aspm/parameters/policy"  >> $initScript;
	fi
	
	# Enable init script
	query=$(cli -c "system init_shutdown_script query" | grep tnsh | wc -l)
	if [ "$query" -lt 1 ] ; then
		chmod ugo+x $initScript
		cli -c "system init_shutdown_script create type=SCRIPT script=\""$initScript"\" when=POSTINIT"
	fi
	
	getInitScript
	readInitConfig
}

#------------------------------------------------------------------------------
# name: moveInitScript
# args: none
# Takes the current init script and moves it to a new locations, updates the
# registration in the TrueNAS SCALE init system, too.
#------------------------------------------------------------------------------
moveInitScript () {
	echo "Not implemented"
	mainMenu
	
	# move actual file, THEN modify entry in init system
	# system init_shutdown_script> update id=8 script="/home/admin/tnshInit.sh"
}

#------------------------------------------------------------------------------
# name: removeInitScript
# args: none
# Deletes the init script and unregisters it from TrueNAS SCALE's init system
#------------------------------------------------------------------------------
removeInitScript () {
	if ! $initExists ; then
		echo "  The init script has not been registered with the system before.";
		read -p "  Press Enter to return to main menu"
	fi
	
	# Ask user for confirmation
	while true; do
		echo "";
		echo "  Deleting the init script will revert all permanent changes after next reboot.";
		read -n 1 -p "  Are your sure that you want to delete the init script? [y/N]  " confirmation
  
		case $confirmation in
		[yY]*)
			echo "";
			
			echo "  Unregistering init script and deleting file."
			
			cli -c "system init_shutdown_script delete id=\""$initScriptId"\""
			
			if $debug ; then
				rm $initScript
			else 
				rm $initScript >> /dev/null
			fi
			
			initExists=false
			getInitScript
			readInitConfig
			read -p "  Press Enter to return to main menu"
			mainMenu
			;;
		''|[nN]*)
			echo "";
			read -p "  Aborting. Press Enter to return to main menu"
			mainMenu
			;;
		*)
			echo "  Invalid choice. Please try again";
		esac
	done
}


#------------------------------------------------------------------------------
# name: recoverInstall
# args: none
# Tries to recover the install in case the init script got lost in an update
#------------------------------------------------------------------------------
recoverInstall () {
	echo "Not implemented"
	mainMenu
	
	# As user if he remembers anything
	# If yes, recover from there
	# If no, do a quick search
}


#------------------------------------------------------------------------------
# name: 
# args: none
# Main program that is called when script is launched
#------------------------------------------------------------------------------

# Check if script is running as root
if [ $(whoami) != 'root' ]; then
	echo "  This script must be run as root. Please try again as root."
	exit;
fi

# Check if running on install boot media
cmdline=$(cat /proc/cmdline | grep "vmlinuz " | grep "boot=live" | wc -l)
if [ "$cmdline" -ge 1 ] ; then
	read -n 1 -p "  Installer environment detected. Do you want to proceed in install mode? [y/n]  " confirmation
  
		case $confirmation in
		[yY]*)
			installModeMenu
			;;
		[nN]*)
			echo "  Continuing in normal mode";
			echo "";
			;;
		*)
			;;
		esac
fi

echo "Searching for configuration ..."

# Get the location of the init script, since it also is config file
getInitScript
readInitConfig

if $debug ; then
	read -p "  Press any key to proceed to main menu when ready"
fi

mainMenu
