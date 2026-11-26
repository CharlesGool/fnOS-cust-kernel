t(){ printf '%-48s ' "$*"; out=$("$@" 2>&1 >/dev/null) && echo OK || echo "DENY(${out##*: })"; }
A="runuser -u admintest --"; U="runuser -u u1 --"
t $A touch /vol1/1000/a.txt
t $A mkdir -p /vol1/1000/dirA
t $A ls /vol1/1000
t $U ls /vol1/1000
t $U cat /vol1/1000/a.txt
t $U touch /vol1/1000/u1-was-here
t $U touch /vol1/1001/u.txt
t $U ls /vol1/1001
t $A ls /vol1/1001
t $A touch /vol1/1001/admin-was-here
t $U rm /vol1/1000/a.txt
t $U ls /vol1
t $U ls /vol1/appcenter-downloads
t $U mkdir /vol1/1001/123
t $A chmod 777 /vol1/1000/dirA
echo "stat modes:"; stat -c '%A %U %n' /vol1/1000 /vol1/1000/a.txt /vol1/1000/dirA /vol1/1001 /vol1/1001/u.txt 2>&1
