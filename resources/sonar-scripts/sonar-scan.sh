#!/bin/bash

PROJECT_ID=
ACCESS_TOKEN=
SONAR_URL=

dotnet sonarscanner begin /k:"$PROJECT_ID" \
    /d:sonar.token="$ACCESS_TOKEN" \
    /d:sonar.cs.opencover.reportsPaths=coverage.xml \
    /d:sonar.host.url="$SONAR_URL" \

dotnet build --no-incremental

coverlet ./unittests/bin/Debug/net9.0/unittests.dll \
    --target "dotnet" \
    --targetargs "test --no-build" \
    -f=opencover \
    -o="coverage.xml"

dotnet sonarscanner end /d:sonar.token="$ACCESS_TOKEN"