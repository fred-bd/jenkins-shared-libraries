#!/bin/bash

OUT_DIR=$(dotnet msbuild unittests -nologo -t:Build -property:Configuration=Debug -getProperty:TargetDir)

#####
# This code would be used with branch plugin for Sonar (I did not make it to work)
#####
# if [ "$BRANCH_NAME" == "main" ]; then
#   dotnet sonarscanner begin /k:"$PROJECT_ID" \
#     /d:sonar.token="$ACCESS_TOKEN" \
#     /d:sonar.cs.opencover.reportsPaths=coverage.xml \
#     /d:sonar.host.url="$SONAR_URL"
# else
#   dotnet sonarscanner begin /k:"$PROJECT_ID" \
#     /d:sonar.token="$ACCESS_TOKEN" \
#     /d:sonar.cs.opencover.reportsPaths=coverage.xml \
#     /d:sonar.host.url="$SONAR_URL" \
#     /d:sonar.pullrequest.key="$BRANCH_NAME" \
#     /d:sonar.pullrequest.branch="$BRANCH_NAME" \
#     /d:sonar.pullrequest.base="main"
# fi

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