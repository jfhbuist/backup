# backup

These are bash scripts for making a backup of data to an external hard drive.
The scripts use the unix utility rsync.
One script is made for MacOS.
The other is for Windows, to be used within Windows Subsystem for Linux (WSL).

## Get started

To get started, you will need to configure the relevant config file (for Mac or WSL) to match your file structure.  
Fill in the locations of your data on your internal drive and on your external drive.  
Then, remove "_template" from the file name.  

Next, open a unix terminal.  
On Mac, this is the usual terminal, while on Windows, this is a WSL terminal.  
Give the script permission to execute:
```
chmod +x backup_WSL.sh
``` 
And then run it. On Windows, the script needs to be run with sudo:
```
sudo ./backup_WSL.sh
```

The script will now prompt the user for additional information on the destination path for the data.

The term "backup letter" refers to a staggered system, where backups are made to two different folders (A and B), in an alternating pattern.
For example, today a backup could be made to folder A. 
A month later, a backup could be made to folder B.
Another month later, the backup would again be made to folder A, so the old backup is overwritten.
This system prevents data loss if a mistake is made or an error occurs during a particular backup.
