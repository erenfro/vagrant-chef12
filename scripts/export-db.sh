#!/bin/bash

if [[ -n "$KNIFE_SECRET_FILE" ]]
then
    KNIFE_SECRET_OFF="$KNIFE_SECRET_FILE"
    unset KNIFE_SECRET_FILE
fi

while read bag
do
    echo "Bag: $bag"
    if [[ ! -d "data_bags/${bag}" ]]
    then
        mkdir -p "data_bags/${bag}"
    fi
    while read item
    do
        echo "+ Item: $item"
        knife data_bag show $bag $item --format=json > "data_bags/${bag}/${item}.json" 2>/dev/null
    done < <(knife data_bag show $bag)
done < <(knife data bag list)

if [[ -n "$KNIFE_SECRET_OFF" ]]
then
    KNIFE_SECRET_FILE="$KNIFE_SECRET_OFF"
    unset KNIFE_SECRET_OFF
fi

