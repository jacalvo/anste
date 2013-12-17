#!/bin/bash
#
# Export the metadata from a VM and generate tar to be used in ANSTE

if [ $# -ne 2 ]; then
    echo "Usage: $0 vm dest_dir"
    exit 1
fi

vm=$1
dest=$2
mkdir $dest/$vm

virsh dumpxml $vm --security-info > $dest/$vm/domain.xml

image=`cat $dest/$vm/domain.xml | grep file= | awk 'BEGIN { FS = "=" } { print $2 }' | cut -c 2- | sed 's/...$//'`

cp $image $dest/$vm/disk.qcow2

tar -cvzf $vm.tar.gz -C $dest $vm
