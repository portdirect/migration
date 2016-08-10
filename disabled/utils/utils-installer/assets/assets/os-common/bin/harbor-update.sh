#!/bin/bash
script=$(cat /tmp/harbor/harbor-update)
exec /tmp/harbor/assets/${script}
