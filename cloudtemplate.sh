# Set this to your Proxmox host name
export ProxmoxHost="pve"
# Set this to the network bridge; most likely vmbr0
export ProxmoxNetworkBridge="vmbr0"
# Set the name of the Storage Volume for Proxmox
export ProxmoxStorageVolume="local-lvm"
# Set the name of the Storage Volume Path - This doesn't do anything at this time
##export ProxmoxStoragePath="/mnt/pve/${ProxmoxStorageVolume}/"
# Set this to the Virtual Machine ID you want to set your template to.
export VMID="800"
# Set the default disk size in gb
export DiskSize="16"
# Set this to the Virtual Machine Template name
export TEMPLATE_NAME="Alma9CloudInit"
# Set your SSH public key
export SSHPUBKEY="xxxxx"
# Set your qcow2 Disk Image Path // example is a generic cloud image
export DiskPath="/root/AlmaLinux-9-GenericCloud-latest.x86_64.qcow2"
# Set your Template Cloud-Init user name
export TemplateUser="arita"

# Create your VM Template
pvesh create /nodes/${ProxmoxHost}/qemu \
    --serial0=socket --vga=serial0 \
    --boot=c --agent=1 \
    --bootdisk=scsi0 \
    --net0='model=virtio,bridge='${ProxmoxNetworkBridge}'' \
    --ide2=${ProxmoxStorageVolume}:cloudinit \
    --sockets=1 --cores=2 --memory=2048 \
    --scsihw='virtio-scsi-pci' \
    --ostype=l26 --numa 0 \
    --template=1 \
    --name=${TEMPLATE_NAME} \
    --vmid=${VMID}<F6>

# Ensure that `jq` is installed on your system
# apt install jq -y

# Import the disk image
qm importdisk ${VMID} ${DiskPath} ${ProxmoxStorageVolume} -f qcow2

# Mount the disk image and set the Cloud-Init settings
pvesh set /nodes/${ProxmoxHost}/qemu/${VMID}/config \
    --scsi0=${ProxmoxStorageVolume}:vm-${VMID}-disk-0 \
    --ipconfig0='ip=dhcp' \
    --ciuser="${TemplateUser}" \
    --sshkeys="$(printf %s "${SSHPUBKEY}" | jq -sRr @uri)"

# Set the boot drive size
pvesh set /nodes/${ProxmoxHost}/qemu/${VMID}/resize \
    --disk=scsi0 --size="${DiskSize}G"
