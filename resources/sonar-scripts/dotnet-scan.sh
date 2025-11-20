#!/bin/bash

OUT_DIR=$(dotnet msbuild unittests -nologo -t:Build -property:Configuration=Debug -getProperty:TargetDir)

dotnet sonarscanner begin /k:"$PROJECT_ID-$BRANCH_NAME" \
    /d:sonar.token="$ACCESS_TOKEN" \
    /d:sonar.cs.opencover.reportsPaths=coverage.xml \
    /d:sonar.host.url="$SONAR_URL" 

dotnet build --no-incremental

coverlet $OUT_DIR/unittests.dll \
    --target "dotnet" \
    --targetargs "test --no-build " \
    -f=opencover \
    -o="coverage.xml" 

dotnet sonarscanner end /d:sonar.token="$ACCESS_TOKEN"