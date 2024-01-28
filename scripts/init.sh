#!/usr/bin/env bash

(
set -e
PS1="$"
basedir="$(cd "$1" && pwd -P)"
workdir="$basedir/base"
minecraftversion=$(cat "$workdir/Paper/BuildData/info.json"  | grep minecraftVersion | cut -d '"' -f 4)
spigotdecompiledir="$workdir/mc-dev/spigot"
nms="$spigotdecompiledir/net/minecraft/server"
cb="src/main/java/net/minecraft/server"
gitcmd="git -c commit.gpgsign=false"

# https://stackoverflow.com/a/38595160
# https://stackoverflow.com/a/800644
if sed --version >/dev/null 2>&1; then
  strip_cr() {
    sed -i -- "s/\r//" "$@"
  }
else
  strip_cr () {
    sed -i "" "s/$(printf '\r')//" "$@"
  }
fi

patch=$(which patch 2>/dev/null)
if [ "x$patch" == "x" ]; then
    patch="$basedir/hctap.exe"
fi

echo "Applying CraftBukkit patches to NMS..."
cd "$workdir/Paper/CraftBukkit"
$gitcmd checkout -B patched HEAD >/dev/null 2>&1
rm -rf "$cb"
mkdir -p "$cb"
# create baseline NMS import so we can see diff of what CB changed
for file in $(ls nms-patches)
do
    patchFile="nms-patches/$file"
    file="$(echo "$file" | cut -d. -f1).java"
    cp "$nms/$file" "$cb/$file"
done
$gitcmd add src
$gitcmd commit -m "Minecraft $ $(date)" --author="Vanilla <auto@mated.null>"

# apply patches
for file in $(ls nms-patches)
do
    patchFile="nms-patches/$file"
    file="$(echo "$file" | cut -d. -f1).java"

    echo "Patching $file < $patchFile"
    set +e
    strip_cr "$nms/$file" > /dev/null
    set -e

    "$patch" -s -d src/main/java/ "net/minecraft/server/$file" < "$patchFile"
done

$gitcmd add src
$gitcmd commit -m "CraftBukkit $ $(date)" --author="CraftBukkit <auto@mated.null>"
$gitcmd checkout -f HEAD~2
)
