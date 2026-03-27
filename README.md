# SEC EDGAR Data Pipeline

Python-based data collection pipeline for retrieving SEC filing metadata and primary filing documents from the SEC EDGAR system.

## Overview

This project automates the retrieval of SEC filing information using company CIK identifiers and supports structured download of filing documents for downstream analysis.

The current workflow includes:
- fetching company submission metadata from the SEC EDGAR data endpoint
- parsing recent filing records
- constructing filing document URLs
- downloading primary filing HTML files
- organizing outputs for future analysis

## Why This Project Matters

Public regulatory filings are an important source of structured and unstructured financial information. This project demonstrates practical experience in:
- public web data collection
- metadata parsing
- document retrieval workflows
- file organization for downstream analytics

## Current Functionality

The current notebook-based workflow supports:
- SEC-compliant request headers
- CIK-based submission lookup
- extraction of recent filing information
- primary document download
- local file storage
- basic rate limiting

## Project Structure

```text
sec-edgar-data-pipeline/
├── README.md
├── requirements.txt
├── data/
│   ├── raw/
│   └── processed/
├── notebooks/
│   └── SEC_API_0.ipynb
├── scripts/
│   ├── fetch_submissions.py
│   ├── download_filings.py
│   └── utils.py
├── outputs/
│   ├── metadata/
│   └── filings_html/
└── figures/
