To clone:<br>
`git clone https://github.com/conciseusa/backup-scripts.git`

This is an effort to roll up the various backup scripts I have written over the years.<br>

Sad I need to write my own scripts for something so common as making backups, but some solutions I found lacked the control I needed, or worse, I would get everything working, and the author of the script would make a breaking change and I would need to waste way too much time reworking and retesting the solution. At some point I gave up a wrote my own.<br>

Not too much here, as this is mostly a wrapper around common commands like rsync and tar, and some simple job control and logging code. But I am posting to make it easy to deploy to my systems, and for my friends that use it in their small businesses.<br>

Much of the work can be setting up the source and/or destination targets. Below is a cheatsheet of commands used to set up targets.<br>

Add drive and reformat:<br>
sudo shred -vf -n 1 /dev/sdb  # not fast, better then wipe, wipe was going to take a very long time<br>
sudo lsblk  # see disks, add -f see type<br>
sudo fdisk -l  # see partitions<br>
sudo fdisk /dev/sdb # command ‘n’, 'p', enter, enter, enter / p to preview, w to write changes - create a partition<br>
sudo mkfs -t ext4 /dev/sdb1<br>

Created mount point /data and ran these before and after mounting so crontab does not need to run as root:<br>
sudo chown -R $USER:$USER /data<br>
sudo chmod -R 770 /data<br>
mkdir -p /data/work  # create area for backups<br>
mount -t ext4  # see mounts,  -t nfs4 see nfs/nas mounts<br>
sudo umount /data  # disconnect mount<br>
sudo mount -av  # run fstab<br>

Connect to NFS target:<br>
https://linuxize.com/post/how-to-mount-an-nfs-share-in-linux/<br>
Installing NFS client on Ubuntu and Debian:<br>
sudo apt update<br>
sudo apt install nfs-common<br>
sudo mkdir /var/public  # Create mount point<br>
sudo nano /etc/fstab<br>
# <file system>     <dir>       <type>   <options>   <dump>	<pass><br>
10.10.0.10:/backups /var/backups  nfs      defaults    0       0<br>
sudo mount -av # run fstab<br>

du -h --max-depth=3  # Review size of data<br>
