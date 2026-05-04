## Run
- target: sec_edgar_pipeline/__main__.py
- action: 1
- role: 3
- extra: none

## Run
- target: sec_edgar_pipeline/pipeline.py
- action: 2
- role: 4
- extra: first 80 lines fetched

## Run
- target: sec_edgar_pipeline/sec_client.py
- action: 2
- role: U
- unknown_entrypoint_check: N
- unknown_core_check: N
- extra: first 80 lines fetched

## Run
- target: sec_edgar_pipeline/converters.py
- action: 1
- role: U
- unknown_entrypoint_check: N
- unknown_core_check: N
- extra: none

## Run
- target: sec_edgar_pipeline/__main__.py
- action: 1
- role: 3
- role_label: python_entrypoint
- extra: none

## Run
- target: sec_edgar_pipeline/pipeline.py
- action: 2
- role: 4
- role_label: core_pipeline_module
- extra: first 80 lines fetched

## Run
- target: sec_edgar_pipeline/sec_client.py
- action: 2
- role: 5
- role_label: sec_api_client_module
- extra: first 80 lines fetched

## Run
- target: sec_edgar_pipeline/converters.py
- action: 1
- role: 6
- role_label: conversion_utility_module
- extra: none

## Run
- target: sec_edgar_pipeline/__main__.py
- action: 1
- role: 3
- role_label: python_entrypoint
- extra: none

## Run
- target: sec_edgar_pipeline/pipeline.py
- action: 2
- role: 4
- role_label: core_pipeline_module
- extra: first 80 lines fetched

## Run
- target: sec_edgar_pipeline/sec_client.py
- action: 2
- role: 5
- role_label: sec_api_client_module
- extra: first 80 lines fetched

## Run
- target: sec_edgar_pipeline/converters.py
- action: 1
- role: 6
- role_label: conversion_utility_module
- extra: none

## Run
- target: sec_edgar_pipeline/sec_client.py
- action: 2
- role: 5
- role_label: sec_api_client_module
- extra: first 80 lines fetched

## Run
- target: sec_edgar_pipeline/converters.py
- action: 1
- role: 6
- role_label: conversion_utility_module
- extra: none

