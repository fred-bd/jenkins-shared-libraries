#!/bin/bash

# PROJECT_ID=
# ACCESS_TOKEN=
# SONAR_URL=
# BRANCH_NAME=

# env
# echo '------'
# echo "ls -la"
# echo "PROJECT_ID=[$PROJECT_ID]"
# echo "ACCESS_TOKEN=[$ACCESS_TOKEN]"
# echo "SONAR_URL=[$SONAR_URL]"
# echo "BRANCH_NAME=[$BRANCH_NAME]"

# ls -la

OUT_DIR=./release

dotnet sonarscanner begin /k:"$PROJECT_ID" \
    /d:sonar.token="$ACCESS_TOKEN" \
    /d:sonar.cs.opencover.reportsPaths=coverage.xml \
    /d:sonar.host.url="$SONAR_URL" \
    /d:sonar.pullrequest.branch="$BRANCH_NAME" \
    /d:sonar.pullrequest.base="main"

dotnet build -c Release -o $OUT_DIR --no-incremental

coverlet $OUT_DIR/unittests.dll \
    --target "dotnet" \
    --targetargs "test --no-build" \
    -f=opencover \
    -o="coverage.xml"

dotnet sonarscanner end /d:sonar.token="$ACCESS_TOKEN"