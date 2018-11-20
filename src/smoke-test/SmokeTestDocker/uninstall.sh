#!/bin/bash

sfctl application delete --application-id SmokeTestDocker
sfctl application unprovision --application-type-name SmokeTestDockerType --application-type-version 1.0.0
sfctl store delete --content-path SmokeTestDocker
