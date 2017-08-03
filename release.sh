#!/bin/sh

VERSION=`grep our\ \$VERSION lib/Grpc/XS.pm|sed "s/.*'\(.*\)';/\1/"`
PACKAGE=grpc-xs-${VERSION}
FILES=`git ls-files|grep -v Vagrantfile|grep -v .gitignore|grep -v release.sh`

## gnu tar only...
tar cvzf ${PACKAGE}.tar.gz ${FILES} --transform s,^,${PACKAGE}/,
