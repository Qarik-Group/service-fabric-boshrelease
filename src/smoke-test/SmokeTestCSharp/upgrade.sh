#!/bin/bash
cd `dirname $0`
sfctl application upload --path SmokeTestCSharp --show-progress
sfctl application provision --application-type-build-path SmokeTestCSharp
sfctl application upgrade --app-id fabric:/SmokeTestCSharp --app-version $1 --parameters "{}" --mode Monitored
cd -