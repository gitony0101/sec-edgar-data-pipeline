# Local Analysis Summary

## Overview
This summary is generated from deterministic outputs.

## Role Statistics
- configuration_module: 1
- conversion_utility_module: 1
- core_pipeline_module: 1
- form_mapping_utility_module: 1
- python_entrypoint: 1
- sec_api_client_module: 1

## File Catalog


## Rules
- This file is generated from controller outputs.
- Role codes and action codes come from deterministic scripts.
- Short descriptions are draft-only unless otherwise marked.

## Entries
### sec_edgar_pipeline/__main__.py

- action: 1
- role: 3
- role_label: python_entrypoint

### sec_edgar_pipeline/pipeline.py

- action: 2
- role: 4
- role_label: core_pipeline_module

### sec_edgar_pipeline/sec_client.py

- action: 2
- role: 5
- role_label: sec_api_client_module

### sec_edgar_pipeline/converters.py

- action: 1
- role: 6
- role_label: conversion_utility_module

### sec_edgar_pipeline/form_map.py

- action: 2
- role: 7
- role_label: form_mapping_utility_module

### sec_edgar_pipeline/config.py

- action: 1
- role: 8
- role_label: configuration_module


## Report Index


## Generated Reports
- sec_edgar_pipeline/__main__.py
  - report: .brain/reports/sec_edgar_pipeline____main__.py.md
- sec_edgar_pipeline/pipeline.py
  - report: .brain/reports/sec_edgar_pipeline__pipeline.py.md
- sec_edgar_pipeline/sec_client.py
  - report: .brain/reports/sec_edgar_pipeline__sec_client.py.md
- sec_edgar_pipeline/converters.py
  - report: .brain/reports/sec_edgar_pipeline__converters.py.md
- sec_edgar_pipeline/form_map.py
  - report: .brain/reports/sec_edgar_pipeline__form_map.py.md
- sec_edgar_pipeline/config.py
  - report: .brain/reports/sec_edgar_pipeline__config.py.md

## Current Status
- baseline_v1 is operational
- rule-first classification is active
- deterministic draft rendering is active
- reports are generated under .brain/reports
