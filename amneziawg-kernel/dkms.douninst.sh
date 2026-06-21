# Remove module's DKMS tree
dkms_tree="/var/lib/dkms"
for f in etc/dkms/framework.conf etc/dkms/framework.conf.d/*.conf; do
  [ -e "$f" ] && . "$f"
done
rm -rf "${dkms_tree#/}/@BUILT_MODULE_NAME@"

# Remove the module itself
rm -f lib/modules/*/@DEST_MODULE_LOCATION@/@BUILT_MODULE_NAME@.ko

chroot . /sbin/depmod --quick
