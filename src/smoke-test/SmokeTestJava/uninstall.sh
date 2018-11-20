#!/bin/bash
set -ex
sfctl application delete --application-id SmokeTestJava
sfctl application unprovision --application-type-name SmokeTestJavaType --application-type-version 1.0.0
sfctl store delete --content-path SmokeTestJava
