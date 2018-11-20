#!/bin/bash
cd `dirname $0`
sfctl application upload --path SmokeTestCSharp --show-progress
sfctl application provision --application-type-build-path SmokeTestCSharp
sfctl application create --app-name fabric:/SmokeTestCSharp --app-type SmokeTestCSharpType --app-version 1.0.0
cd -
