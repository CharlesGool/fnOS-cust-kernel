t(){ printf '%-52s ' "$*"; out=$("$@" 2>&1 >/dev/null) && echo OK || echo "DENY(${out##*: })"; }
A="runuser -u admintest --"; U="runuser -u u1 --"
getfattr -h -e hex -n system.trim_acl /vol1/1000/dirB 2>&1 | grep trim_acl
t $U ls /vol1/1000/dirB
t $U cat /vol1/1000/dirB/f.txt
t $U touch /vol1/1000/dirB/u1new
t $U rm /vol1/1000/dirB/f.txt
t $U ls /vol1/1000
t $A ls /vol1/1000/dirB
