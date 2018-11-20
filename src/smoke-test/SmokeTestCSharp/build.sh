#!/bin/bash
DIR=`dirname $0`
source $DIR/dotnet-include.sh

dotnet restore $DIR/../SmokeTestCSharp/src/SmokeTestCSharp/SmokeTestCSharp.Interfaces/SmokeTestCSharp.Interfaces.csproj -s https://api.nuget.org/v3/index.json
dotnet build $DIR/../SmokeTestCSharp/src/SmokeTestCSharp/SmokeTestCSharp.Interfaces/SmokeTestCSharp.Interfaces.csproj -v normal

dotnet restore $DIR/../SmokeTestCSharp/src/SmokeTestCSharp/SmokeTestCSharpService/SmokeTestCSharpService.csproj -s https://api.nuget.org/v3/index.json
dotnet build $DIR/../SmokeTestCSharp/src/SmokeTestCSharp/SmokeTestCSharpService/SmokeTestCSharpService.csproj -v normal
cd `dirname $DIR/../SmokeTestCSharp/src/SmokeTestCSharp/SmokeTestCSharpService/SmokeTestCSharpService.csproj`
dotnet publish -o ../../../../SmokeTestCSharp/SmokeTestCSharp/SmokeTestCSharpPkg/Code
cd -


dotnet restore $DIR/../SmokeTestCSharp/src/SmokeTestCSharp/SmokeTestCSharpTestClient/SmokeTestCSharpTestClient.csproj -s https://api.nuget.org/v3/index.json
dotnet build $DIR/../SmokeTestCSharp/src/SmokeTestCSharp/SmokeTestCSharpTestClient/SmokeTestCSharpTestClient.csproj -v normal
cd `dirname $DIR/../SmokeTestCSharp/src/SmokeTestCSharp/SmokeTestCSharpTestClient/SmokeTestCSharpTestClient.csproj`
dotnet publish -o ../../../../SmokeTestCSharp/SmokeTestCSharpServiceTestClient
cd -
