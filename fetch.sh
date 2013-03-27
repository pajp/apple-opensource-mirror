#!/bin/bash -e

for release; do
    ./mirror.rb --release "$release" | grep -v '^#' | xargs ./mirror.rb --release "$release"
    [ ${PIPESTATUS[0]} -eq 0 ] && [ ${PIPESTATUS[0]} -eq 0 ]
done