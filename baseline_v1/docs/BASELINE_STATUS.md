# Baseline Status

## Stage
baseline_v1 frozen

## Confirmed strengths
- local Codex + Ollama + gemma4:e2b pipeline can run
- deterministic evidence extraction works
- rule-first file classification works for core files
- action logging and catalog logging work

## Confirmed limitations
- Gemma is not reliable for exact dependency/version copying
- Gemma is not reliable for strict long-form structured output
- Gemma freeform explanations may drift
- trusted facts must stay outside the model

## Core principle
Use scripts for truth.
Use Gemma only in narrow, low-risk roles.

## Promoted design
rule first + facts first + logging first

## Human summary
We successfully built a small local analysis baseline.
The stable path is:
deterministic extraction -> rule-first decision -> optional extra evidence -> logging.
Gemma should only be used in narrow constrained roles.
