#!/bin/bash
cd `dirname $0`
sfctl application upload --path SmokeTestJava --show-progress
sfctl application provision --application-type-build-path SmokeTestJava
sfctl application upgrade --app-id fabric:/SmokeTestJava --app-version $1 --parameters "{}" --mode Monitored
cd -