#!/usr/bin/env bash
rm -rf public && npx antora --fetch local-playbook.yml
cp css/*.css public/_/css/
find public/ -name "*.html" -exec sed -i "s/[^/][a-z]\+\.css/wide-site\.css/" {} \;
