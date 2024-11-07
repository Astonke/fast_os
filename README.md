# fast_os
create a linux os to any drive

#req
on current debian linux env

#install debootstrap
sudo apt install debootstrap

#give permissions to script and exceute providing drive (/dev/sdx)

sudo chmod 777 os_maker.sh
./os_maker.sh /dev/sdx
