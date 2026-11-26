#!/bin/bash
# fnOS-cust-kernel build entry point, run on the build host. Configuration comes from .env (see .env.example).
#   ck.sh container               create the build container (debian:12 + build dependencies + pahole from source)
#   ck.sh fetch [upstream]        download into $CK_DEPS_DIR and verify: linux-<upstream>.tar.xz (kernel.org signature),
#                                 the ZFS tarball and the module source archive of this project (sha256 in config/versions.conf)
#   ck.sh fetch-nvidia --accept-nvidia-license
#                                 optional: download the NVIDIA proprietary driver .run and unpack its kernel/ sources;
#                                 read third_party/nvidia-linux-driver/LICENSE first
#   ck.sh bootstrap               create the kernel tree and the ZFS tree from source tarballs + patches/
#   ck.sh kernel|zfs|pkg          run one build step
#   ck.sh extmod [name...]        build out-of-tree modules (all by default)
#   ck.sh build                   kernel + zfs + extmod + pkg; output in $CK_DEPS_DIR/ck/out/
#   ck.sh release                 copy the built package into releases/<VERSION>/ with SHA256SUMS and BUILDINFO
#   ck.sh srcpkg                  put the release sources into releases/<VERSION>/: module source archive, upstream tarballs, NVIDIA license
#   ck.sh export                  export local commits of the kernel, ZFS and module trees back into patches/
#   ck.sh saveconfig              save the kernel tree .config as config/config-<kernel release>
#   ck.sh newbase <upstream>      add a new upstream base to the kernel tree and rebase the patches onto it
#   ck.sh status                  show the version and the state of the trees
set -euo pipefail
REPO=$(cd "$(dirname "$0")/.." && pwd)
[ -f "$REPO/.env" ] && { set -a; . "$REPO/.env"; set +a; }
: "${CK_DEPS_DIR:?set CK_DEPS_DIR in .env (see .env.example)}"
CK_CONTAINER_DIR=${CK_CONTAINER_DIR:-/k}
CK_BUILD_CONTAINER=${CK_BUILD_CONTAINER:-kwork}
CK_DOCKER=${CK_DOCKER:-docker}
KC=$CK_DEPS_DIR                      # upstream tarballs, module sources and the work area; not in Git
W=$KC/ck                             # work area: kernel tree, ZFS tree, build dirs, output
. "$REPO/config/versions.conf"
VERSION=$(cat "$REPO/config/VERSION"); UPV=${VERSION%-*}; KREL=$UPV$LOCALVER
die(){ echo "error: $*" >&2; exit 1; }
# get <url> <file> <sha256>: download unless present, then verify
get(){ [ -f "$2" ] || { curl -fL --retry 5 --retry-all-errors -o "$2.part" "$1" && mv "$2.part" "$2"; } || die "download failed: $1"
       echo "$3  $2" | sha256sum -c --quiet || { rm -f "$2"; die "sha256 mismatch: $2 (deleted, run again)"; }; }
sync_repo(){ mkdir -p $W/repo; rsync -a --delete --exclude .git --exclude .local --exclude releases --exclude test "$REPO/" $W/repo/; }
kw(){ sync_repo; $CK_DOCKER exec -e CK_K="$CK_CONTAINER_DIR" -e KJOBS="${KJOBS:-}" -e ALLOW_CONFIG_CHANGE="${ALLOW_CONFIG_CHANGE:-}" \
        "$CK_BUILD_CONTAINER" bash "$CK_CONTAINER_DIR/ck/repo/scripts/kwork/$@"; }
cmd=${1:-}; shift || true
case $cmd in
  fetch)
    V=${1:-$UPV}; cd $KC
    [ -f linux-$V.tar.xz ] || curl -fsSLO https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-$V.tar.xz
    curl -fsSL -o sha256sums.asc https://cdn.kernel.org/pub/linux/kernel/v6.x/sha256sums.asc
    export GNUPGHOME=${CK_GNUPGHOME:-$KC/gnupg}; mkdir -p -m700 $GNUPGHOME
    gpg -q --auto-key-locate clear,wkd --locate-keys autosigner@kernel.org >/dev/null 2>&1 || true
    # must be a valid signature by the kernel.org checksum autosigner (fixed fingerprint)
    gpg --status-fd 1 --verify sha256sums.asc 2>/dev/null | grep -q '^\[GNUPG:\] VALIDSIG B8868C80BA62A1FFFAF5FDA9632D3A06589DA6B1 ' || die "bad signature on sha256sums.asc"
    grep -E " linux-${V//./\\.}\.tar\.xz\$" sha256sums.asc | sha256sum -c
    [ -f linux-$V.tar.sign ] || curl -fsSLO https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-$V.tar.sign
    [ "$V" = "$UPV" ] || exit 0
    mkdir -p dl-zfs-$ZFS; Z=https://github.com/openzfs/zfs/releases/download/zfs-$ZFS/zfs-$ZFS.tar.gz
    get $Z dl-zfs-$ZFS/zfs-$ZFS.tar.gz $ZFS_SHA256
    [ -f dl-zfs-$ZFS/zfs-$ZFS.tar.gz.asc ] || curl -fsSL -o dl-zfs-$ZFS/zfs-$ZFS.tar.gz.asc $Z.asc
    # module sources: unpack every MANIFEST.tsv directory that is missing; .ck-rev records its commit.
    # The NVIDIA proprietary directory is never taken from the archive (see fetch-nvidia).
    N=fnos-cust-kernel-$EXTSRC_VER-extmod-src; U=extsrc/.unpack; mkdir -p extsrc; rm -rf $U
    grep -v '^#' "$REPO/patches/extmod/MANIFEST.tsv" | while IFS=$'\t' read -r d br base head n; do
      [ $d = nvidia-prop-work ] || [ -e extsrc/$d/.git ] && continue
      if [ -e extsrc/$d ]; then
        [ "$(cat extsrc/$d/.ck-rev 2>/dev/null)" = "$head" ] && continue
        [ -f extsrc/$d/.ck-rev ] || die "extsrc/$d is neither a Git repository nor unpacked by fetch"
        rm -rf extsrc/$d   # unpacked from an older archive
      fi
      if [ ! -d $U ]; then
        get $CK_RELEASES/v$EXTSRC_VER/$N.tar.xz $N.tar.xz $EXTSRC_SHA256
        mkdir $U; tar -xJf $N.tar.xz -C $U --exclude=$N/nvidia-prop-work
      fi
      [ -d $U/$N/$d ] || die "$N.tar.xz has no $d"
      echo $head > $U/$N/$d/.ck-rev; mv $U/$N/$d extsrc/$d; echo "unpacked extsrc/$d"
    done; rm -rf $U
    [ -d extsrc/nvidia-prop-work ] || echo "note: no NVIDIA proprietary sources; the build skips nvidia-gpu-proprietary (see ck.sh fetch-nvidia)" ;;
  fetch-nvidia)
    [ "${1:-}" = --accept-nvidia-license ] || die "read third_party/nvidia-linux-driver/LICENSE, then run: ck.sh fetch-nvidia --accept-nvidia-license"
    F=NVIDIA-Linux-x86_64-$NVIDIA_PROP.run; mkdir -p $KC/dl-nvidia-prop
    get https://download.nvidia.com/XFree86/Linux-x86_64/$NVIDIA_PROP/$F $KC/dl-nvidia-prop/$F $NVIDIA_PROP_SHA256
    kw nvidia-prop.sh ;;
  container)
    $CK_DOCKER inspect "$CK_BUILD_CONTAINER" >/dev/null 2>&1 && die "container $CK_BUILD_CONTAINER already exists"
    mkdir -p $KC; $CK_DOCKER run -d --name "$CK_BUILD_CONTAINER" -v "$KC:$CK_CONTAINER_DIR" debian:12 sleep infinity >/dev/null
    kw container.sh ;;
  bootstrap) kw bootstrap.sh ;;
  kernel|zfs|pkg) kw $cmd.sh "$@" ;;
  extmod) kw extmod.sh "$@" ;;
  build) kw kernel.sh && kw zfs.sh && kw extmod.sh && kw pkg.sh ;;
  release)
    D=$W/out/linux-image-${KREL}_${VERSION}_amd64.deb; [ -f $D ] || die "missing $D, run ck.sh build first"
    O="$REPO/releases/$VERSION"; [ -e "$O/$(basename $D)" ] && die "$O already has this package; released versions are never overwritten"
    mkdir -p "$O"; cp $D "$O/"; cp $W/out/BUILDINFO-$VERSION "$O/BUILDINFO"
    (cd "$O" && sha256sum *.deb > SHA256SUMS && grep -q "$(cut -d' ' -f1 SHA256SUMS)" BUILDINFO) || die "sha256 mismatch after copy"
    echo "copied to $O" ;;
  srcpkg)
    O="$REPO/releases/$VERSION"; mkdir -p "$O"; T=$(mktemp -d); N=fnos-cust-kernel-$VERSION-extmod-src
    grep -v '^#' "$REPO/patches/extmod/MANIFEST.tsv" | while IFS=$'\t' read -r d br base head n; do
      [ $d = nvidia-prop-work ] && continue   # NVIDIA proprietary sources are not redistributed; users fetch them (fetch-nvidia)
      [ "$(git -C $KC/extsrc/$d rev-parse HEAD)" = "$head" ] || die "$d HEAD differs from MANIFEST.tsv"
      mkdir -p $T/$N/$d; git -C $KC/extsrc/$d archive HEAD | tar -x -C $T/$N/$d
    done
    cp "$REPO/patches/extmod/MANIFEST.tsv" $T/$N/
    tar -C $T --owner=0 --group=0 --sort=name -cJf "$O/$N.tar.xz" $N; rm -rf $T
    echo "set EXTSRC_VER=$VERSION and EXTSRC_SHA256=$(sha256sum "$O/$N.tar.xz" | cut -d' ' -f1) in config/versions.conf before tagging"
    # complete corresponding source for the package: upstream tarballs with signatures, plus the NVIDIA license
    cp $KC/linux-$UPV.tar.xz $KC/linux-$UPV.tar.sign $KC/dl-zfs-$ZFS/zfs-$ZFS.tar.gz $KC/dl-zfs-$ZFS/zfs-$ZFS.tar.gz.asc "$O/"
    cp "$REPO/third_party/nvidia-linux-driver/LICENSE" "$O/NVIDIA-LICENSE.txt"
    (cd "$O" && sha256sum *.deb *.tar.* NVIDIA-LICENSE.txt BUILDINFO > SHA256SUMS); ls -l "$O" ;;
  export)
    rm -f "$REPO"/patches/kernel/*.patch; git -C $W/linux format-patch -q --no-signature -o "$REPO/patches/kernel" v$UPV..HEAD
    (cd "$REPO/patches/kernel" && ls *.patch > series)
    rm -f "$REPO"/patches/zfs/*.patch; git -C $W/zfs format-patch -q --no-signature -o "$REPO/patches/zfs" zfs-$ZFS..HEAD
    M="$REPO/patches/extmod/MANIFEST.tsv"; T=$(mktemp); head -1 "$M" > $T
    grep -v '^#' "$M" | while IFS=$'\t' read -r d br base head n; do
      b=${base%% *}; g="git -C $KC/extsrc/$d"; n=$($g rev-list --count $b..HEAD)
      printf '%s\t%s\t%s\t%s\t%s\n' "$d" "$($g branch --show-current)" "$base" "$($g rev-parse HEAD)" "$n" >> $T
      rm -rf "$REPO/patches/extmod/$d"; [ "$n" = 0 ] || $g format-patch -q --no-signature -o "$REPO/patches/extmod/$d" $b..HEAD
    done; mv $T "$M"; git -C "$REPO" status --short patches | head -20 ;;
  saveconfig) cp $W/linux/.config "$REPO/config/config-$KREL"; echo "saved config/config-$KREL" ;;
  newbase)
    N=${1:?usage: ck.sh newbase <new upstream version, e.g. 6.18.66>}; T=$KC/linux-$N.tar.xz; [ -f $T ] || die "run ck.sh fetch $N first"
    cd $W/linux; [ -z "$(git status --porcelain --untracked-files=no)" ] || die "the kernel tree has uncommitted changes"
    git rev-parse -q --verify v$N >/dev/null && die "v$N already exists"
    git checkout -q -b base-$N v$UPV; git ls-files -z | xargs -0 rm -f
    tar -xf $T --strip-components=1 -C .; git add -A >/dev/null; git -c user.name=kcmp -c user.email=kcmp@localhost commit -qm "linux-$N upstream (signature verified)"; git tag v$N
    git checkout -q -b r$N r$UPV
    git -c user.name=kcmp -c user.email=kcmp@localhost rebase --onto v$N v$UPV || { echo "rebase conflicts: resolve them in $W/linux, then git rebase --continue"; exit 1; }
    echo "rebased onto v$N (branch r$N). Next: set config/VERSION to $N-1, ck.sh export, ck.sh build" ;;
  status)
    echo "VERSION=$VERSION KREL=$KREL ZFS=$ZFS work area=$W"
    [ -d $W/linux/.git ] && echo "kernel tree: $(git -C $W/linux describe --tags) branch $(git -C $W/linux branch --show-current)" || echo "kernel tree: none (ck.sh bootstrap)"
    [ -d $W/zfs/.git ] && echo "ZFS tree: $(git -C $W/zfs describe --tags)" || true
    ls "$REPO/releases" 2>/dev/null || true ;;
  *) sed -n 2,19p "$0"; exit 1 ;;
esac
