#!/bin/bash

# PROJECT_ID=
# ACCESS_TOKEN=
# SONAR_URL=
# BRANCH_NAME=

dotnet sonarscanner begin /k:"$PROJECT_ID" \
    /d:sonar.token="$ACCESS_TOKEN" \
    /d:sonar.cs.opencover.reportsPaths=coverage.xml \
    /d:sonar.host.url="$SONAR_URL" \
    /d:sonar.pullrequest.branch="$BRANCH_NAME" \
    /d:sonar.pullrequest.base="main"

dotnet build -c Release -o ./release --no-incremental

coverlet ./release/unittests.dll \
    --target "dotnet" \
    --targetargs "test --no-build" \
    -f=opencover \
    -o="coverage.xml"

dotnet sonarscanner end /d:sonar.token="$ACCESS_TOKEN"