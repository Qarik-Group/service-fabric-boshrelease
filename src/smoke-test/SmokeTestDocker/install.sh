#!/bin/bash

sfctl application upload --path SmokeTestDocker --show-progress
sfctl application provision --application-type-build-path SmokeTestDocker
sfctl application create --app-name fabric:/SmokeTestDocker --app-type SmokeTestDockerType --app-version 1.0.0
