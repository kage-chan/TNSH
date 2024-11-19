<p align="center">
  <a>
    <img src="https://raw.githubusercontent.com/kage-chan/HomeLab/main/TNSH/screenshot.png" alt="TNSH Screenshot" height="250">
    <h1 align="center">TrueNAS SCALE Helper Script</h1>
  </a>
</p>

<p align="center">
  A little helper to customize TrueNAS SCALE installs for resource efficiency.
</p>


## ❓ Why?
TrueNAS SCALE has a few shortcomings for home users with highly efficient, low idle power servers. For example, TrueNAS SCALE will always block all space on the boot drive, it cannot be used for other things. The power management also leaves a lot to be desired of you want to minimize idle power. K3s (backend used for containers in TrueNAS SCALE) causes a considerable permanent load on the CPU, even without containers running. This prevents the CPU from entering higher c states (it's not a bug, it's a feature... that's what the devs say). All these things added up, so I wanted to have a few things changed in my TrueNAS SCALE installation. To document and make things easier for future me, I've made a script to help me. Feel free to use it, but be sure that
YOU ARE OUTSIDE WHAT iX-System DOES SUPPORT, SO YOU WILL BE ON YOUR OWN! And please, always always always back up your data.
Why shell script you ask? I've never really done anything "serious" with shell scripts, so I am trying to learn shell scripting along this project. Should you spot anything that is utterly wrong or has room for improvement, open up that issue and tell me! 👍

## ✅ Things the script can do
With the disclaimer out of the way, here's what the script can do fo you:
- confine TrueNAS SCALE to size-adjustable partition and make rest of the disk available
- optimize power management (temporarily and permanently)
- install a basic docker environment with portainer to manage containers
- install HAOS in a VM for you

## ❌ Things the script can't do
- make system disk's space available when you've already installed TrueNAS SCALE
- you will not be able to use TrueNAS SCALE's UI to manage Apps/Containers

# ⛏️ Usage
Regardless of the mode your're running the TrueNAS SCALE Helper in, it will show you a menu and guide you through all steps as neccessary. But, the script still is in it's very early stages, there might still be rought edges around here and there. I strongly encourage you to open an issue should you spot something 😊

>[!NOTE]
>Although not strictly neccessary, it is recommended to run the script directly on the machine instead of using ssh. For most commands this does not pose a problem, but especially when creating a container for docker network settings are being messed with. These changes in network settings will likely cut your network connection to the machine, at least temporarily. Therefore, if possible try to run it on the machine directly or at least have means to find the new IP of the machine in case the network configuration changes!

## 🔨 During TrueNAS SCALE install
To install TrueNAS SCALE on a partition instead of the whole disk, the script offers a convenient "installer mode", which is only active if you start the script from the TrueNAS SCALE environment. To use the script, please choose "Shell" from the installer menu. In the shell, make sure that you have internet access (if not, check below) and run the following code:
```
curl -O https://github.com/kage-chan/TNSH/raw/refs/heads/main/TNSH.sh
chmod +x TNSH.sh
./TNSH.sh
```

Alternatively, if you trust URL-shorteners, feel free to use this shortened version of the URL:
```
curl -o TNSH.sh -OL https://tinyurl.com/muw36ara
chmod +x TNSH.sh
./TNSH.sh
```

The script will detect the TrueNAS SCALE installer environment and prompt you. After confirming, please choose the size of the partition for TrueNAS SCALE. You'll be guided back into the actual installer, where you can carry on with the install as usual.

### Should you have no internet connection
On all my machines I tested 24.10, the installer wasn't able to correctly resolve domain names, it seems like it ignored the DNS server supplied by the DHCP server. To fix this, open `/etc/resolve.conf` with vi and add the following line:
```
nameserver 1.1.1.1
```

This will use cloudflare to resolve domain names during the install. Alternatively use the DNS server of your liking.


>[!CAUTION]
>Please make sure the partition size you choose is smaller than the disk's size, otherwise the install will fail. In that case, just reboot from the installer stick and retry. **The script does not check this at the current stage!**

>[!TIP]
>Remember to leave room for your services partition (where your docker environment will be living)

## 🏚️ After the install
To use the script, simply download it and make it executable. The script MUST be run as root, since it does work with pretty important system settings.
```
curl -O https://github.com/kage-chan/TNSH/raw/refs/heads/main/TNSH.sh
chmod +x TNSH.sh
sudo ./TNSH.sh
```

Alternatively, if you trust URL-shorteners, feel free to use this shortened version of the URL:
```
curl -o TNSH.sh -OL https://tinyurl.com/muw36ara
chmod +x TNSH.sh
./TNSH.sh
```
