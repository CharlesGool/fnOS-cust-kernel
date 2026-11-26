#!/bin/bash
# fnOS-cust-kernel build entry point, run on the build host. Configuration comes from .env (see .env.example).
#   ck.sh fetch [upstream]        download linux-<upstream>.tar.xz into $CK_DEPS_DIR and verify the kernel.org signature
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
    grep -E " linux-${V//./\\.}\.tar\.xz\$" sha256sums.asc | sha256sum -c ;;
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
      [ "$(git -C $KC/extsrc/$d rev-parse --short=12 HEAD)" = "$head" ] || die "$d HEAD differs from MANIFEST.tsv"
      mkdir -p $T/$N/$d; git -C $KC/extsrc/$d archive HEAD | tar -x -C $T/$N/$d
    done
    cp "$REPO/patches/extmod/MANIFEST.tsv" $T/$N/
    tar -C $T --owner=0 --group=0 --sort=name -cJf "$O/$N.tar.xz" $N; rm -rf $T
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
      printf '%s\t%s\t%s\t%s\t%s\n' "$d" "$($g branch --show-current)" "$base" "$($g rev-parse --short=12 HEAD)" "$n" >> $T
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
  *) sed -n 2,14p "$0"; exit 1 ;;
esac
