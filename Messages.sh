#!/usr/bin/env bash

set -o errexit

# have to unset LANGUAGE as a work-around of a ruby-locale bug
# http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=670320
unset LANGUAGE
cat > kubeplayer.pot <<HEADER
# Language template for Kubeplayer
#
# Copyright (C) 2012
HEADER
kdegettext.rb `find lib -iname \*.rb` >> kubeplayer.pot