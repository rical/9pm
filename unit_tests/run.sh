#!/bin/bash
#
# Copyright (C) 2011-2014 Richard Alpe <rical@highwind.se>
#
# This file is part of 9pm.
#
# 9pm is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# 9pm is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

#TODO: Handle arguments (like debug and log)

base=$(dirname $(readlink -f $0))
tool=$base/../9pm.py

echo "* Running all automated test, all should be OK!"
$tool --option cmdl-supplied $base/auto.yaml

echo "* Running TAP test on all states, should mark run as fail."
$tool $base/tap/ok-skip-fail-states.yaml

echo "* Running TAP test on ok and skip states, should mark run as skip."
$tool $base/tap/ok-skip-states.yaml

echo "* Running TAP test on ok state, should mark run as ok."
$tool $base/tap/ok-states.yaml
