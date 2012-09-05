#!/bin/bash

for release; do
    ./mirror.rb --release "$release" | grep -v '^#' | xargs ./mirror.rb --release "$release"
done