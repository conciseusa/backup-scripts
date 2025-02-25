To clone:<br>
`git clone https://github.com/conciseusa/backup-scripts.git`

This is an effort to roll up the various backup scripts I have written over the years.<br>

Sad I need to write my own scripts for something so common as making backups, but some solutions I found lacked the control I needed, or worse, I would get everything working, and the author of the script would make a breaking change and I would need to waste way too much time reworking and retesting the solution. At some point I gave up a wrote my own.<br>

Not too much here, as this is mostly a wrapper around common commands like rsync and tar, and some simple job control and logging code. But I am posting to make it easy to deploy to my systems, and for my friends that use it in their small businesses.<br>

Some features the script provides: a semaphore that prevents the script from starting up if a previous job has not completed, an optional size reduction check that aborts sync jobs to prevent a deleted source from wiping out the backups, logic to prevent deleting the last rolling tar backup.<br>

setup.sh creates a config dir in the parent dir and copies in the bujobs.sh file that can be modified to run the needed jobs. It has some sample jobs that write to the tmp dir.<br>

Much of the work can be setting up the source and/or destination targets. Below is a cheatsheet of commands used to set up targets. It may, or may not, be helpful depending on the goal.<br>
Common scenarios are cleaning up a hard drive with data on it and formatting it to hold backup data,<br>
and connecting to a NAS to backup data on the NAS, or storing backup data on the NAS.<br>

Add drive and reformat:<br>
sudo lsblk  # see disks, add -f see type<br>
Replace /dev/sdx with the drive you want to wipe, if it has data already,  and reformat<br>
sudo shred -vf -n 1 /dev/sdx  # not fast, better then wipe, wipe was going to take a very long time<br>
sudo fdisk -l  # see partitions<br>
sudo fdisk /dev/sdx # command ‘n’, 'p', enter, enter, enter / p to preview, w to write changes - create a partition<br>
<br>
If "fdisk: DOS partition table format cannot be used on drives for volumes larger than 2199023255040 bytes for 512-byte sectors"<br>
sudo parted /dev/sdx<br>
(parted) mklabel gpt<br>
(parted) print<br>
(parted) quit<br>
sudo reboot now, log back in<br>
<br>
sudo mkfs -t ext4 /dev/sdx1<br>
/dev/sdx1 should be ready to use, but not mounted.<br>

sudo blkid # Listing all UUIDs, used drive model to name mount point, can choose any valid filename<br>
fstab has many tutorials, basic use below<br>
Sample line in /etc/fstab so mounts at startup - sudo nano /etc/fstab<br>
UUID="becfc46b-d6bc-4abd-9eb9-8d4dfd441fe1"  /mnt/ST4000NM0033-9ZM  ext4  defaults  0  0<br>

Create data dir and open to current user so crontab does not need to run as root:<br>
sudo mkdir -p /mnt/ST4000NM0033-9ZM/data  # create area for backups<br>
cd /mnt/ST4000NM0033-9ZM<br>
sudo chown -R $USER:$USER data<br>
sudo chmod -R 770 data<br>

mount -t ext4  # see mounts, mount -t nfs4 see nfs/nas mounts<br>
sudo umount /data  # disconnect mount<br>
sudo mount -av  # run fstab<br>

Connect to NFS target:<br>
https://linuxize.com/post/how-to-mount-an-nfs-share-in-linux/<br>
Installing NFS client on Ubuntu and Debian:<br>
sudo apt update<br>
sudo apt install nfs-common<br>
sudo mkdir /var/backup-scripts  # Create mount point<br>
sudo nano /etc/fstab<br>
file system     dir       type   options   dump	pass<br>
10.10.0.10:/nasdata /var/backup-scripts  nfs      defaults    0       0<br>
sudo mount -av # run fstab<br>

Use /var/backup-scripts created above for local backups:<br>
cd /var/backup-scripts<br>
sudo mkdir local<br>
sudo chown -R $USER:$USER local<br>
sudo chmod -R 770 local<br>
Now should be able to use /var/backup-scripts/local<br>
for backups without being root.<br>

du -h --max-depth=3  # Review size of data<br>

If the backup server is placed in an out of the way location,<br>
it can be helpful to have remote access to the GUI.<br>
Different solutions seem to work, then stop working over the years(VNC, NoMachine, etc.).<br>
RDP seems to be working well as of 2023 on Mint Linux<br>
sudo apt install xrdp xorgxrdp -y<br>
echo env -u SESSION_MANAGER -u DBUS_SESSION_BUS_ADDRESS cinnamon-session>~/.xsession<br>
Thanks for the setup guide: https://www.rootisgod.com/2020/Using-RDP-With-Linux-Mint-20-Cinnamon/<br>
