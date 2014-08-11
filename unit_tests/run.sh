#!/bin/bash
#
# Copyright (C) 2011-2014 Richard Alpe <rical@highwind.se>
#
# This file is part of 9pm.
#
# 9pm is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# 9pm is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with 9pm.  If not, see <http://www.gnu.org/licenses/>.

#TODO: Handle arguments (like debug and log)

cd $(dirname $(readlink -f $0))

find . -mindepth 1 -maxdepth 1 -type d -name "*test" | while read DIR;
do
    echo "### Running tests in $DIR ###"
    cd "$DIR"
    "${DIR}.tcl" -d #TODO: Check return code and act appropriate
    cd ..
    echo ""
done

