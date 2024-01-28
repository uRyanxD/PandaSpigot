#!/usr/bin/env bash

(
set -e
PS1="$"
basedir="$(cd "$1" && pwd -P)"
workdir="$basedir/base"
minecraftversion=$(cat "$workdir/Paper/BuildData/info.json"  | grep minecraftVersion | cut -d '"' -f 4)
windows="$([[ "$OSTYPE" == "cygwin" || "$OSTYPE" == "msys" ]] && echo "true" || echo "false")"
decompiledir="$workdir/mc-dev"
spigotdecompiledir="$decompiledir/spigot"
classdir="$decompiledir/classes"

# prep folders
mkdir -p "$spigotdecompiledir"

if [ ! -d "$classdir" ]; then
    echo "Extracting NMS classes..."
    mkdir -p "$classdir"
    cd "$classdir"
    set +e
    jar xf "$decompiledir/$minecraftversion-mapped.jar" net/minecraft/server yggdrasil_session_pubkey.der assets
    if [ "$?" != "0" ]; then
        cd "$basedir"
        echo "Failed to extract NMS classes."
        exit 1
    fi
    set -e
fi

# if we see the old net folder, copy it to spigot to avoid redecompiling
if [ -d "$decompiledir/net" ]; then
    cp -r "$decompiledir/net" "$spigotdecompiledir/"
fi

if [ ! -d "$spigotdecompiledir/net" ]; then
    echo "Decompiling classes (stage 2)..."
    cd "$basedir"
    set +e
    java -jar "$workdir/Paper/BuildData/bin/fernflower.jar" -dgs=1 -hdc=0 -rbr=0 -asc=1 -udv=0 "$classdir" "$spigotdecompiledir"
    if [ "$?" != "0" ]; then
        rm -rf "$spigotdecompiledir/net"
        echo "Failed to decompile classes."
        exit 1
    fi
    set -e
fi
)
