#!/bin/sh

echo "RPM Script Launching"

echo "Copying the payload into place"
/bin/cp -Rf /payload/* /

echo "Making the install script executible"
chmod +x /install-pipework.sh

echo "Running the install script"
/bin/bash -c /install-pipework.sh

echo "Tidying up"
rm -rf /install-pipework.sh

echo "RPM Script Complete"
