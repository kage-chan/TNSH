#!/bin/bash

# http://www.patorjk.com/software/taag/#p=display&c=echo&f=Shaded%20Blocky&t=TrueNAS%20SCALE
#  _____             _____ _____ _____    _____ _____ _____ __    _____ 
# |_   _|___ _ _ ___|   | |  _  |   __|  |   __|     |  _  |  |  |   __|
#   | | |  _| | | -_| | | |     |__   |  |__   |   --|     |  |__|   __|
#   |_| |_| |___|___|_|___|__|__|_____|  |_____|_____|__|__|_____|_____|
#                                                                      
# TrueNAS SCALE Helper by Daniel Ketel, 2024
# For latest version visit https://github.com/kage-chan/HomeLab/TNSH
# TrueNAS® is a registered Trademark of IXsystems, Inc.
#

# Settings that are user-editable
debug=false;

# Global variables
version="0.65"
initExists=false
initScript=""
initScriptId=0
configPower=false
configDocker=false
dockerExists=false
dockerPath=""
dockerCommand=""
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
	echo " https://github.com/kage-chan/HomeLab/TNSH";
	echo "";
	
	if $initExists ; then
		echo ""
		echo -e "  ${F_BOLD}${C_GREY0}${C_LIME}Init script found at:${NO_FORMAT}" $initScript
		echo -n "  Configured: "
		if $configPower ; then
			echo -n -e "${F_BOLD}${C_GOLD1}Power${NO_FORMAT}"
		fi
		if $configDocker ; then
			echo -n -e " ${F_BOLD}${C_DODGERBLUE1}Docker${NO_FORMAT}"
		fi
		echo ""
		
		if $configDocker ; then
			echo "  Docker container's path:" $dockerPath
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
	echo "  Press 2 to install Docker, Portainer & Watchtower";
	echo "  Press 3 to install HomeAssistant OS in a VM";
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
			installDocker
			break
			;;
		[3]*)
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
# name: installDocker
# args: none
# Installs a systemd-nspawn container, optionally install docker & co inside
#------------------------------------------------------------------------------
installDocker () {
	bridgeToUse=""
	useExistingBridge=false
	useBridge=true
  
	# First check if container already exists in default location
	if $dockerExists ; then
		# Check if container is running
		$running=$(machinectl | grep dockerNspawn | wc -l)
		if [ $var -ge 1 ] ; then
			echo ""
			echo "Docker already running";
			read -p "  Aborting. Press Enter to return to main menu"
			mainMenu
		fi
		
		# What to do if it exists but is not running?
	fi

	# First, ask if user wants to use network bridge for docker container
	while true; do
		echo "";
		echo "  If you want your docker container to have an own IP reachable from the hosts network";
		read -n 1 -p "  it needs to use a network bridge. Do you want to use a network bridge? [Y/n]  " useBridge
		
		case $useBridge in
		'')
			useBridge=true
			break
			;;
		[yY]*)
			useBridge=true
			break
			;;
		[nN]*)
			useBridge=false
			break
			;;
		*)
			echo ""
			echo "  Invalid selection. Please select yes or no."
			continue
		esac
	done
	
	
	# If a bridge network is to be used, get all current network interfaces
	if $useBridge ; then
		ifaces=$(ifconfig -s | tail -n +2)
		interfaces=()
		bridges=()
		j=1
		while read -ra dev; do
			if $debug ; then
				echo "  "$j".  "${dev[0]};
			fi
	
			interfaces+=(${dev[0]})
			
			# Detect existing network bridges
			if [[ ${dev[0]} == br[0-9]* ]] ; then
				bridges+=(${dev[0]})
				
				if $debug ; then
					echo "  Network bridge" ${dev[0]} "detected.";
				fi
			fi
		
			((j=j+1))
		done <<< "$ifaces"
	fi
	
	# USE EXISTING NETWORK BRIDGE
	# if one is detected and user agrees to use it
	if [ "${#bridges[@]}" -ge 1 ] && [ $useBridge ] ; then
		while true; do
			echo "";
			echo "  Detected existing network bridge(s). Would you like to use one of the existing"
			read -n 1 -p "  network bridge(s) with the docker container? [Y/n] " selectedInterface
			
			case $selectedInterface in
			''|[yY]*)
				# USE EXISTING BRIDGE
				# If there is more than one bridge, let user choose bridge
				if [ "${#bridges[@]}" -eq 1 ] ; then
					echo "";
					echo "  Detected only one bridge, will use" ${bridges[0]};
					bridgeToUse=${bridges[0]}
					break;
				fi
				
				# If there is more than one bridge, let user choose bridge
				echo "";
				echo "  Available network bridges:";
				echo "  0.  Abort";
				j=1
				for i in "${bridges[@]}"; do
					echo "  "$j"."  $i;
					((j=j+1))
				done
				
				while true; do
					read -n 1 -p "  Select network bridge to use: [0-"$((j-1))"] " selectedBridge
		
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
						read -p "  Press Enter to return to the main menu"
						mainMenu
					fi
				
					bridgeToUse=${bridges[(($selectedBridge-1))]}
					useExistingBridge=true
					break
				done
				break
				;;
			[nN]*)
				break
				;;
			*)
				echo ""
				echo "  Invalid selection. Please select yes or no."
				continue
			esac
		done
	fi
	
	# CREATE NEW NETWORK BRIDGE
	# If no bridge was detected or user does not want to use existing bridge
	echo ""
	if [ -z $bridgeToUse ] && [ $useBridge == true ] ; then
		while true; do
			echo "  To create a new network bridge, you must tell the script through which interface"
			echo "  you currently are connected to the host network."
			echo "";
			echo "  0.  Abort";
			
			j=1
			for i in "${interfaces[@]}"; do
				echo "  "$j". "  $i;
				((j=j+1))
			done
			
			read -n 1 -p "  Select network interface currently in use: [0-"$((j-1))"] " selectedInterface
			
			# Check if input is numeric
			re='^[0-9]'
			if ! [[ $selectedInterface =~ $re ]] ; then
				echo "";
				echo "  Error: Not a number. Please try again.";
				continue
			fi

			# Check if selection is higher than list length
			if [ "$selectedInterface" -gt "${#interfaces[@]}" ] ; then
				echo "  Error: Not a valid option"
				continue
			fi
			
			# Return to menu if user requested abort
			if [[ "$selectedInterface" == 0 ]]; then
				echo "";
				echo "  Aborted";
				read -p "  Press any key to return to the main menu"
				mainMenu
			fi
			
			# TODO Check if selected interface is already member of other bridge
			
			break
		done
		
		# Find next free network bridge name (br[0-9]*). If no bridge was found
		# we don't need to do anything, since the default (defined above) name
		# for the bridge "br0" will be used
		if [ "${#bridges[@]}" == 0 ] ; then
			bridgeToUse="br0"
		fi
		
		if [ "${#devices[@]}" -ge 1 ] ; then
			# Search with awk '{for(i=p+1; i<$1; i++) print i} {p=$1}' file
			# TODO
			echo ""
		fi
		
		# Create the new network bridge if required
		cli -c "network interface update \""${interfaces[(($selectedInterface-1))]}"\" ipv4_dhcp=false"
		cli -c "network interface create name=\""$bridgeToUse"\" type=BRIDGE bridge_members=\""${interfaces[(($selectedInterface-1))]}"\" ipv4_dhcp=true"
		cli -c "network interface commit"
		cli -c "network interface checkin"
	fi
  
	# Check if services partition exists and suggest placing container there
	if test -d /mnt/services ; then
		echo "";
		echo "  TNSH-services partition detected. The suggested location for the container is";
		echo "  /mnt/services/dockerNspawn. It is recommended to use this location, since it does";
		echo "  ensure that the container will also survive TrueNAS SCALE updates.";
		
		read -n 1 -p "  Do you want to place the script in the suggested location? [Y/n]  " suggestedLocation
  		
		case $suggestedLocation in
		''|[yY]*)
			dockerPath="/mnt/services/dockerNspawn"
			;;
		[nN]*)
			choosePath=true
			;;
		*)
			echo "  Invalid choice. Please try again";
		esac
	fi
  
	# Create systemd-nspawn "container" (ask user which filesystems to "import" there?)
	
	if $choosePath ; then
		while true; do
			echo " ";
			read -p "  Please specify directory to use for the container: " pathForContainer
			
			if [[ -z "$pathForContainer" ]] ; then
				echo ""
				echo "  Please specify a valid absolute path!";
				echo ""
				continue
			fi
			
			if [[ $pathForContainer != /* ]] ; then
				echo ""
				echo "  Please specify a valid absolute path!";
				echo ""
				continue
			fi
			
			if [[ ! -d "$pathForContainer" ]] ; then
				echo "";
				echo "  Directory does not exist. Creating.";
				echo "";
			fi
			
			dockerPath=$pathForContainer
			break
		done
		
		if [[ $pathForContainer != /mnt/* ]] ; then
			echo "";
			echo "  Path is inside a system dataset.";
			echo "  The container might be damaged or removed during future TrueNAS SCALE updates.";
			echo "  Please be aware of this and periodically backup your container.";
			echo "";
			
			if [[ $pathForContainer == */ ]] ; then
				dockerPath=$pathForContainer
			else
				dockerPath=$pathForContainer"/"
			fi
			break
		fi
	fi
	
	# TODO
	# If folder exists, check if it contains a container and if it can be reconstructed
	#if [[ -d "$pathForContainer" ]] ; THEN
	#fi
	
	echo "  Searching for pools now ..."
	
	pls=$(cli -c "storage pool query" | tail -n +4 | head -n -1)

	if $debug ; then
			echo "  Query returned the following pool(s): ";
			echo "$pls"
	fi

	pools=()
	paths=()
	while read -ra pool; do
			j=1
			for i in "${pool[@]}" ; do
					if [ $j -eq 4 ] ; then
							if $debug ; then
									echo -n "  Pool name is" $i;
							fi
							pools+=($i)
					fi
					if [ $j -eq 8 ] ; then
							if $debug ; then
									echo " with path" $i;
							fi
							paths+=($i)
					fi
					((j=j+1))
			done
	done <<< "$pls"
	
	echo ""
	echo "  Found a total of ${#pools} pools."
	echo ""
	
	while true; do
		read -n 1 -p "  Would you like to bind one ore more of them to the container? [Y/n]  " bindPools
  		
		case $bindPools in
		''|[yY]*)
			bindPools=true
			break
			;;
		[nN]*)
			bindPools=false
			break
			;;
		*)
			echo "  Invalid choice. Please try again";
		esac
	done
	
	if $bindPools ; then
		echo ""
		echo "  0.  None";
		
		for i in $(seq 1 "${#pools[@]}") ; do
			echo "  "$i". "${pools[$(($i-1))]};
		done
		
		read -n 1 -p "  Which of the pools would you like to bind to the container? [0-${#pools[@]}]  " poolToBind
  		
		poolToBind=${paths[$(($poolToBind-1))]}
		echo "";
	fi
	
	# Install docker inside the container (ask if portainer + watchtower)
	if ! $dockerExists ; then
		mkdir -p $dockerPath
	fi
	cd $dockerPath
	# A kind thank you to the nspawn team for letting me use this link in this script
	wget https://hub.nspawn.org/storage/debian/bookworm/tar/image.tar.xz
	#cp /mnt/services/image.tar.xz ./
	mkdir rootfs
	tar -xf image.tar.xz -C rootfs
	rm rootfs/etc/machine-id
	rm rootfs/etc/resolv.conf
	touch rootfs/etc/securetty
	for i in $(seq 0 10); do
		echo "pts/"$i >> rootfs/etc/securetty
	done
	
	command="systemd-run --property=KillMode=mixed --property=Type=notify --property=RestartForceExitStatus=133 --property=SuccessExitStatus=133 --property=Delegate=yes --property=TasksMax=infinity --collect --setenv=SYSTEMD_NSPAWN_LOCK=0 --unit=dockerNspawn --working-directory="$dockerPath" '--description=systemd-nspawn container creates by TNSH to run docker' --setenv=SYSTEMD_SECCOMP=0 --property=DevicePolicy=auto -- systemd-nspawn --keep-unit --quiet --boot --machine=dockerNspawn --directory=rootfs --capability=all '--system-call-filter=add_key keyctl bpf'"
	if $useBridge ; then
		command="$command --network-bridge=br0 --resolv-conf=bind-host"
	fi
	if $bindPools ; then
		command="$command --bind='$poolToBind:$poolToBind'"
	fi
	
	eval "$command"
	
	echo "  Waiting for container to start and network connection to be configured"
	echo -n "  30s..."
	sleep 5
	echo -n "  25s..."
	sleep 5
	echo -n "  20s..."
	sleep 5
	echo -n "  15s..."
	sleep 5
	echo -n "  10s..."
	sleep 1
	echo -n "  9s..."
	sleep 1
	echo -n "  8s..."
	sleep 1
	echo -n "  7s..."
	sleep 1
	echo -n "  6s..."
	sleep 1
	echo -n "  5s..."
	sleep 1
	echo -n "  4s..."
	sleep 1
	echo -n "  3s..."
	sleep 1
	echo -n "  2s..."
	sleep 1
	echo -n "  1s..."
	sleep 1
	
	
	# Install docker inside container
	machinectl shell dockerNspawn /usr/bin/apt update
	machinectl shell dockerNspawn /usr/bin/apt install -y ca-certificates curl
	machinectl shell dockerNspawn /bin/install -m 0775 -d /etc/apt/keyrings
	machinectl shell dockerNspawn /bin/curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
	machinectl shell dockerNspawn /bin/chmod a+r /etc/apt/keyrings/docker.asc

	echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian bookworm stable" > rootfs/etc/apt/sources.list.d/docker.list
	machinectl shell dockerNspawn /usr/bin/apt update
	machinectl shell dockerNspawn /usr/bin/apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
	
	# Install watchtower if users agrees
	while true; do
		echo "";
		read -n 1 -p "  Install watchtower? [Y/n]  " installWatchtower
		
		case $installWatchtower in
		''|[yY]*)
			machinectl shell dockerNspawn /usr/bin/docker run --detach --name watchtower --volume /var/run/docker.sock:/var/run/docker.sock containrrr/watchtower
			break
			;;
		[nN]*)
			break
			;;
		*)
			echo ""
			echo "  Invalid selection. Please select yes or no."
			continue
		esac
	done
	
	# Install portainer if users agrees
	while true; do
		echo "";
		read -n 1 -p "  Install portainer? [Y/n]  " installWatchtower
		
		case $installWatchtower in
		''|[yY]*)
			machinectl shell dockerNspawn /usr/bin/docker volume create portainer_data
			machinectl shell dockerNspawn /usr/bin/docker run -d -p 8000:8000 -p 9443:9443 --name portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:latest
			break
			;;
		[nN]*)
			break
			;;
		*)
			echo ""
			echo "  Invalid selection. Please select yes or no."
			continue
		esac
	done
	
	# Add code to init script that starts container at boot post init
	dockerCommand=$command
	buildInitScript DOCKER 
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
			[DOCKER]*)
				if $debug ; then
					echo "  Docker configured in init script"
				fi
				configDocker=true
				;;
			/*)
				if $debug ; then
					echo "  Docker rootfs path is:" $i
				fi
				
				if [ -d $i ] ; then
					dockerExists=true
				fi
				
				dockerPath=$i
				;;
			*)
			esac
		done
	fi
}


#------------------------------------------------------------------------------
# name: getDockerConfig
# args: none
# Gets current configuration of the docker install like bridge, binds etc.
# note: will store extracted config in global variables
#------------------------------------------------------------------------------
getDockerConfig () {
	# Check if docker config file exists
	# If it exists, "read" config file.
	# If it does not exist, attempt to build one?
	echo "";
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
	[DOCKER]*)
		configDocker=true
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
	
	if $configDocker == true ; then
		echo -n " DOCKER" >> $initScript;
		echo -n " "$dockerPath >> $initScript;
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
	
	if $configDocker == true; then
		echo ""  >> $initScript;
		echo "# Docker container"  >> $initScript;
		echo $dockerCommand >> $initScript;
		echo ""  >> $initScript;
		echo ""  >> $initScript;
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
