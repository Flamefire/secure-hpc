#!/bin/bash
# Script to encrypt the run script with receiver being slurm
# it is assumed that the user has the slurm recipient on the key ring
# result is a file named $file_name.gpg
file_name=$1
recipient=$2
gpg --armor --recipient $recipient --encrypt $file_name
