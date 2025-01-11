#!/bin/bash
DIR=$(pwd)
schemacrawler --server=postgresql --host=localhost --port=55432 --database=framework --schemas=public --user=framework --password=framework --info-level=standard --command=schema --output-format=png --output-file=${DIR}/database_diagram.png