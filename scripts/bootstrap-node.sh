#!/bin/bash

knife bootstrap $1 -r 'role[node]' --sudo --secret-file /etc/chef/encrypted_data_bags

