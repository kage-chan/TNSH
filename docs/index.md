---
title: Home
layout: home
nav_order: 1
---

# Welcome to the TNSH docs
TrueNAS SCALE Helper (TNSH) is a helper script to help you automate certain tasks in [TrueNAS SCALE]. This page will explain the main ideas behind the script. Click the links in the navigation to get instruction for each of the operations.
The original idea was to modify TrueNAS SCALE to run more energy efficiently for my [efficient home server build].

The main features at this stage (v0.7) are:
- Free up and make available unused system disk space
- Optimize power management
- Install docker (permanently) to replace k3s
- Install HAOS in a VM

The script is menu guided and I've tried my best to keep the usage as easy as possible. Still, it is far from perfect an I hope with this documentation and some in-depth articles I can assist anyone who has come here to use the script.

# General considerations
The script basically has two operating modes:
- installation mode
- post-install mode

The script can detect if it is run from an TrueNAS SCALE installation medium. If it detects being run from an TrueNAS SCALE installation medium, your options will be limited to confining the TrueNAS SCALE install to a partition on the disk, instead of filling the whole disk. The remaining space on the disk can be used as a "services" partition. Most of the time you'll be spending in post-install mode.

# The services partition
The design of the script is that you confine TrueNAS SCALE to a small partition (typically 32 GB) on the disk and use the rest of the disk as a partition for services. The idea of the services partition is to have a permanently available space outside yout data RAID to use for services as docker or HAOS. There are two reasons I personally see the need for this:
1. Anything stored on the system disk (or partition) will be lost during TrueNAS SCALE updates. So putting docker & co. on the system disk is not an option.
2. Putting the services on to the data RAID will spin up the disks more often, or even prevent them from spinning down at all.

So all services this script offers will by default be stored inside the services partition. At this point (v0.7) HAOS can only be installed inside the services partition, but changing that is planned for a future release. 

[TrueNAS SCALE]: https://www.truenas.com/truenas-scale/
[efficient home server build]: https://www.danielketel.com/tag/efficient-home-server/