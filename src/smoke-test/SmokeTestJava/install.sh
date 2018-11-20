#!/bin/bash
set -ex
sfctl application upload --path SmokeTestJava --show-progress
sfctl application provision --application-type-build-path SmokeTestJava
sfctl application create --app-name fabric:/SmokeTestJava --app-type SmokeTestJavaType --app-version 1.0.0
