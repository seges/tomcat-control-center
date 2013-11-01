#!/bin/bash

tcc_dir=`dirname $0`
tcc_user=tcc
tcc_group=tcc

chown -R $tcc_user:$tcc_group $tcc_dir
chmod g+x $tcc_dir/bin/*.sh
chmod -R g+r $tcc_dir
chmod -R g+w $tcc_dir
