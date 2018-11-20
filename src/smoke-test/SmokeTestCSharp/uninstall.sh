#!/bin/bash

sfctl application delete --application-id SmokeTestCSharp
sfctl application unprovision --application-type-name SmokeTestCSharpType --application-type-version 1.0.0
sfctl store delete --content-path SmokeTestCSharp