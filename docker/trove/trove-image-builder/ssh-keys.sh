#
# Copyright 2014 Hewlett-Packard Development Company, L.P.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#

if [ ${DIB_DEBUG_TRACE:-1} -gt 0 ]; then
    set -x
fi
set -eu
set -o pipefail

if [ -d $TMP_MOUNT_PATH/${DIB_MANIFEST_IMAGE_DIR} ]; then
    # Move the dib_environment and dib_arguments files into the manifests dir
    if [ -e $TMP_MOUNT_PATH/etc/dib_arguments ]; then
        sudo mv $TMP_MOUNT_PATH/etc/dib_arguments $TMP_MOUNT_PATH/${DIB_MANIFEST_IMAGE_DIR}
    fi
    if [ -e $TMP_MOUNT_PATH/etc/dib_environment ]; then
        sudo mv $TMP_MOUNT_PATH/etc/dib_environment $TMP_MOUNT_PATH/${DIB_MANIFEST_IMAGE_DIR}
    fi
    sudo mkdir -p ${DIB_MANIFEST_SAVE_DIR}
    sudo cp --no-preserve=ownership -rv $TMP_MOUNT_PATH/${DIB_MANIFEST_IMAGE_DIR} \
        ${DIB_MANIFEST_SAVE_DIR}
fi
