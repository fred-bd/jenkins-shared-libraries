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

OUT_DIR="$PWD/release"

OUTDIR=$(dotnet msbuild -nologo -t:Build -property:Configuration=Release -getProperty:TargetDir)
echo "Output directory: $OUTDIR"


dotnet sonarscanner begin /k:"$PROJECT_ID" \
    /d:sonar.token="$ACCESS_TOKEN" \
    /d:sonar.cs.opencover.reportsPaths=coverage.xml \
    /d:sonar.host.url="$SONAR_URL" 
    # \
    # /d:sonar.pullrequest.branch="$BRANCH_NAME" \
    # /d:sonar.pullrequest.base="main"

# dotnet build -c Release -o $OUT_DIR --no-incremental
dotnet build --no-incremental

# echo '----'
# echo "out: $OUT_DIR"
# ls -la $OUT_DIR
# echo '----'
# ls -la $PWD/unittests

coverlet $OUT_DIR/unittests.dll \
    --target "dotnet" \
    --targetargs "test flux-micro-svc.sln --no-build " \
    -f=opencover \
    -o="coverage.xml" --verbosity detailed

dotnet sonarscanner end /d:sonar.token="$ACCESS_TOKEN"