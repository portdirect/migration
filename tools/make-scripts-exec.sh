#/bin/sh
find . -type f -name "*.sh" -exec bash -c 'chmod +x "$0"' {} \;
find . -type f -name "*.py" -exec bash -c 'chmod +x "$0"' {} \;
