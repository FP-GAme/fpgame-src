#!/bin/bash

echo "FP-GAme Autorun Script Starting"

if ! [ -e "/home/root/game" ]; then
    echo "/home/root/game NOT FOUND! Cannot autorun game"
else
    echo "Found game! Starting..."
    cd /home/root && ./game
fi
