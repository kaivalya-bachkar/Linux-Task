#!/bin/bash
# NFS Setup Script - Works for both Server and Client configuration
# Author: Kaivalya Bachkar

echo "----------------------------------------"
echo "   NFS Configuration Script (Server/Client)"
echo "----------------------------------------"
echo
echo "Select setup type:"
echo "1) NFS Server"
echo "2) NFS Client"
read -p "Enter choice (1 or 2): " choice

# =========================
# NFS SERVER CONFIGURATION
# =========================
if [ "$choice" == "1" ]; then
    echo "---- Setting up NFS Server ----"
    sudo dnf install -y nfs-utils

    sudo systemctl start nfs-server.service
    sudo systemctl enable nfs-server.service
    sudo systemctl status nfs-server.service --no-pager

    # Create directories
    sudo mkdir -p /mnt/nfs_shares/kaivalya
    sudo mkdir -p /mnt/backups

    # Get IP inputs
    read -p "Enter Server IP for /mnt/nfs_shares/kaivalya access: " server_ip1
    read -p "Enter Client IP for /mnt/backups access: " client_ip2

    # Write exports configuration
    echo "/mnt/nfs_shares/kaivalya ${server_ip1}(rw,sync)" | sudo tee /etc/exports
    echo "/mnt/backups ${client_ip2}(rw,sync,no_all_squash,no_root_squash)" | sudo tee -a /etc/exports

    # Export NFS shares
    sudo exportfs -arv

    # Configure firewall
    sudo firewall-cmd --permanent --add-service=nfs
    sudo firewall-cmd --permanent --add-service=rpc-bind
    sudo firewall-cmd --permanent --add-service=mountd
    sudo firewall-cmd --reload

    # Create test file
    sudo touch /mnt/backups/file_created_on_server.text

    echo
    echo "✅ NFS Server setup completed successfully!"
    echo "Exported shares:"
    sudo exportfs -v

# =========================
# NFS CLIENT CONFIGURATION
# =========================
elif [ "$choice" == "2" ]; then
    echo "---- Setting up NFS Client ----"
    sudo dnf install -y nfs-utils nfs4-acl-tools

    read -p "Enter NFS Server IP: " server_ip

    # Show available NFS exports
    sudo showmount -e "$server_ip"

    # Create mount directories
    sudo mkdir -p /mnt/backups /mnt/nfs_shares

    # Mount remote share
    sudo mount -t nfs ${server_ip}:/mnt/backups /mnt/backups

    # Add entry to /etc/fstab
    echo "${server_ip}:/mnt/backups /mnt/backups nfs defaults 0 0" | sudo tee -a /etc/fstab

    echo
    echo "Checking file from server..."
    ls -l /mnt/backups/file_created_on_server.text || echo "⚠️ File not found — verify mount!"

    echo "✅ NFS Client setup completed successfully!"

else
    echo "Invalid choice. Please run the script again and choose 1 or 2."
    exit 1
fi
