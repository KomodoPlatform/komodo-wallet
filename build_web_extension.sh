#!/bin/bash

# If things don't work, make sure you have extension compatible mm2 in web/src/mm2

# Replace the generated index.html with the extension custom index.html
cp web/index_extension.html web/index.html

# Clean the build folder
rm -r build

# Build the extension
flutter build web --csp --web-renderer=canvaskit --no-web-resources-cdn
#flutter build web --web-renderer html --csp --profile
#flutter build web --web-renderer html --csp
