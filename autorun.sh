#! /usr/bin/env bash
echo 'Performance Benchmarking'
echo 'Created by Kirk Ryan - b-kiryan@microsoft.com'
echo 'V1.0 - March 2020 - No warrantees or liabilities are made of any kind.'

# Roadmap
# Add auto-installation of fio
# Send results to data visualiser (benchmarking.kirkryan.co.uk)

# Assumptions
# - Azure NetApp Files volume is provisioned
# - User has already installed the appropriate NFS or SMB client
# - User has already install fio

# Options
protocol="nfs" # Set your test protocol: Options are nfs, smb or local
automount="true" # Set to true if you would like to automatically mount and run the tests, otherwise set to false if file system is already mounted
latency_target='1000' # TODO - allow setting a latency target to find max performance at a given latency
START=1 # Do not change
numdirs='1' # Number of directories to generate for directory testing
numfiles='1000' # Number of files to generate for file testing

# Target Variables
mountpath="/mnt"
mountdir="anf"
targetpath="10.0.1.4:/demo-01" # If NFS or SMB specify the path here i.e. "10.0.0.4:/volume1"

# Globals
osname=`cat /etc/os-release | grep ^NAME`
osversion=`cat /etc/os-release | grep ^VERSION_ID`

# Environmental Checks

# FIO installation check
fiocheck=`command -v fio`
if [[ $fiocheck == *"fio"* ]];
then
    echo "fio detected"
else
    echo "Warning:  fio not installed - please install fio via 'yum install fio' or 'apt install fio'"
    echo "Would you like to continue and skip bandwidth and latency testing? (y/n)"
    read continuetests
    if [[ $continuetests == "n" ]];
    then
        exit 1
    fi
fi


# [ -f "/path/to/some/${dir}/" ]

# Automount NFS
echo "Automount was $automount"
if [[ "$automount" == "true" && "$protocol" == "nfs" ]];
then
    echo "NFS Automount ENABLED: Mounting target $protocol file system ($targetpath)"
    cd $mountpath
    sudo mkdir $mountdir

    # Use for Ubuntu 19.10 and other distros with nconnect support
    if [[ $osname == *"Ubuntu"* && $osversion == *"19.10"* ]]; 
    then
        echo "OS supports use of nconnect - connecting with optimised NFS options"
        sudo mount -t nfs -o rw,hard,nconnect=16,rsize=65536,wsize=65536,vers=3,tcp $targetpath "$mountpath/$mountdir"
    else
        # RHEL and other distributions that do not support nconnect
        echo "OS does not support nconnect - connecting with standard NFS options"
        sudo mount -t nfs -o rw,hard,rsize=65536,wsize=65536,vers=3,tcp $targetpath "$mountpath/$mountdir"
    fi
    
    sudo chmod 777 $mountdir
    cd $mountdir
    echo "NFS Automount Successful: Filesystem Ready"
else
    echo "NFS Automount DISABLED: Skipping automount of target file system"
fi
# SMB (via Samba)
# TODO add smb mount logic
if [[ $automount == "true" && $protocol == "smb" ]];
then
    echo "SMB Automount ENABLED: Mounting target $protocol file system ($targetpath)"
    echo "SMB is a WIP, wait for next version :-)"
else
    echo "SMB Automount DISABLED: Skipping automount of target file system"
fi

if [[ $automount == "true" && $protocol == "local" ]];
then
    echo "Local Disk Testing Enabled"
    cd $mountpath
    mkdir $mountdir
else
    echo "Local Disk Testing Disabled - Testing NFS/SMB target"
fi

echo 'Starting Throughput Benchmark...'

# Linux
fio ~/64kseqreads.ini ~/64kseqwrites.ini ~/4krandreads.ini ~/4krandwrites.ini

# Windows
# TODO

echo 'Finished Throughput Benchmark...'

# File Simulation Benchmark Logic

echo 'Starting File Benchmark...'
echo "Simulating Creation and Deletion of $numdirs Directories and $numfiles Files"

echo Started: `date` > time.txt
started=`date +%s`
mkdir testdir1

for (( d=$START; d<=$numdirs; d++ ))

do

mkdir testdir1/${d}

        for (( c=$START; c<=$numfiles; c++ ))

        do

        echo hello > "testdir1/${d}/File${c}.txt"

        done

done

echo Created: `date` >> time.txt

created=`date +%s`

rm -rf testdir1

echo Finished: `date` >> time.txt

finished=`date +%s`

createtime=$((created-started))

deletetime=$((finished-created))

totaltime=$((finished-started))

echo Creation took: $createtime

echo Deletion took: $deletetime

echo Total time: $totaltime

#TODO - Send results via HTTPS POST to service endpoint for visualisation and report generation
#TODO - Capture system information such as OS, version, patch levels and VM Size (if Azure)