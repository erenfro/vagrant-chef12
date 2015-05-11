#!/bin/bash

BRANCH=$(git rev-parse --abbrev-ref HEAD)
git pull --rebase origin $BRANCH
git push origin $BRANCH
knife environment from file environments/*.rb
knife role from file roles/*.rb
knife data bag from file -a
knife cookbook upload -a

