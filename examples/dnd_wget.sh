#!/bin/sh
../dnd | while read url
do
    wget "$url"
done
