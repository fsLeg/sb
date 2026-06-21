dkms_tree="/var/lib/dkms"
for f in etc/dkms/framework.conf etc/dkms/framework.conf.d/*.conf; do
  [ -e "$f" ] && . "$f"
done
rm -rf "${dkms_tree#/}/amneziawg"
