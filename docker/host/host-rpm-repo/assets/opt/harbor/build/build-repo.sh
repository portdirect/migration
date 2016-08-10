#!/bin/sh

# Make sure that the correct structure is in place
mkdir -p /srv/repo/atomic-host/7/{SRPMS,i386,x86_64,noarch} && \
chown -R $(whoami) /srv/repo/atomic-host/7/{SRPMS,i386,x86_64,noarch}

destdir="/srv/repo/atomic-host/7/"
for arch in SRPMS i386 x86_64 noarch
do
    pushd ${destdir}/${arch} >/dev/null 2>&1
    	rm -rf repodata
        createrepo .
    popd >/dev/null 2>&1
done
