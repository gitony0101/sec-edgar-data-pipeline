#!/usr/bin/env python
import sys
import os
import json
import re
import subprocess
import time

# --- CONFIGURATION ---
MODEL = "gemma4:e2b"
MAX_RETRIES = 2
DEBUG_DIR = ".brain/debug_fill"
REQUIRED_KEYS = [
    "current_observations",
    "possible_overlap",
    "possible_cleanup",
    "needs_cross_check_with",
    "next_action"
]
SECTION_MAPPING = {
    "current_observations": "CURRENT_OBSERVATIONS",
    "possible_overlap": "POSSIBLE_OVERLAP",
    "possible_cleanup": "POSSIBLE_CLEANUP",
    "needs_cross_check_with": "NEEDS_CROSS_CHECK_WITH",
    "next_action": "NEXT_ACTION"
}

def get_fallback_json():
    """Returns a deterministic fallback structure if model fails completely."""
    return {
        "current_observations": ["- Uncertain: Model failed or output invalid."],
        "possible_overlap": ["- Uncertain: Model failed or output invalid."],
        "possible_cleanup": ["- Uncertain: Model failed or output invalid."],
        "needs_cross_check_with": ["- Uncertain: Model failed or output invalid."],
        "next_action": ["- Observed: Review note was created.", "- Possible: Manual review required."]
    }

def call_local_model(prompt, attempt=0):
    """Calls ollama API directly for JSON output."""
    try:
        url = "http://localhost:11434/api/generate"
        payload = {
            "model": MODEL,
            "prompt": prompt,
            "stream": False,
            "format": "json"
        }
        
        # Save prompt for debugging
        os.makedirs(DEBUG_DIR, exist_ok=True)
        with open(f"{DEBUG_DIR}/last_prompt_attempt_{attempt}.txt", 'w') as f:
            f.write(prompt)

        cmd = ["curl", "-s", "-X", "POST", url, "-H", "Content-Type: application/json", "-d", json.dumps(payload)]
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        
        response_json = json.loads(result.stdout)
        raw_response = response_json.get("response", "").strip()
        
        # Save raw response for debugging
        with open(f"{DEBUG_DIR}/last_response_attempt_{attempt}.json", 'w') as f:
            f.write(raw_response)
            
        return raw_response
    except Exception as e:
        print(f"Error calling ollama API: {e}", file=sys.stderr)
        return None

def extract_json(text):
    """Attempts to find and parse JSON block in text, handling ANSI codes and extra text."""
    if not text:
        return None
    
    # 1. Strip ANSI escape codes
    ansi_escape = re.compile(r'''
        \x1B  # ESC
        (?:   # 7-bit C1 Fe target
            [@-Z\\-_]
        |     # or [ [v...m] or [ [v...K], etc.
            \[
            [0-?]*  # Parameter bytes
            [ -/]*  # Intermediate bytes
            [@-~]   # Final byte
        )
    ''', re.VERBOSE)
    text = ansi_escape.sub('', text)
    text = text.replace('\x00', '')

    # 2. Try finding markdown code block (relaxed)
    match = re.search(r'```(?:json)?\s*\n?(.*?)\n?```', text, re.DOTALL | re.IGNORECASE)
    if match:
        content = match.group(1).strip()
        try:
            return json.loads(content)
        except json.JSONDecodeError:
            pass
            
    # 3. Try finding any { ... } block (the outermost one)
    match = re.search(r'(\{.*\})', text, re.DOTALL)
    if match:
        content = match.group(1).strip()
        try:
            return json.loads(content)
        except json.JSONDecodeError:
            pass
            
    # 4. Fallback: try literal match
    try:
        return json.loads(text.strip())
    except json.JSONDecodeError:
        pass
            
    return None

def validate_and_normalize_json(data):
    """Checks if all required keys exist, normalizes values to lists of unique strings."""
    if not isinstance(data, dict):
        return None
    
    normalized = {}
    for key in REQUIRED_KEYS:
        # 1. Ensure key exists
        val = data.get(key, [])
        
        # 2. Normalize to list
        if not isinstance(val, list):
            val = [str(val)] if val else []
            
        # 3. Clean and prefix each item
        cleaned_items = []
        for item in val:
            s = str(item).strip()
            if not s:
                continue
            # Remove existing bullet prefixes if any to re-apply consistently
            s = re.sub(r'^[-*+]\s*', '', s)
            if s:
                cleaned_items.append(f"- {s}")
        
        # 4. Deduplicate while preserving order
        unique_items = []
        seen = set()
        for item in cleaned_items:
            if item not in seen:
                unique_items.append(item)
                seen.add(item)
        
        # 5. Fallback if empty
        if not unique_items:
            unique_items = ["- Uncertain: Not provided."]
            
        normalized[key] = unique_items
            
    return normalized

def fill_note(note_path, json_data):
    """Updates the target markdown note with the JSON data safely."""
    if not os.path.exists(note_path):
        print(f"Error: Note path {note_path} does not exist.", file=sys.stderr)
        return

    with open(note_path, 'r') as f:
        lines = f.readlines()

    new_lines = []
    skip_mode = False
    found_headers = set()
    
    # Map header names to their JSON keys
    header_to_key = {v: k for k, v in SECTION_MAPPING.items()}

    for line in lines:
        matched_header = None
        for h in SECTION_MAPPING.values():
            if line.startswith(f"## {h}"):
                matched_header = h
                break
        
        if matched_header:
            new_lines.append(line)
            key = header_to_key[matched_header]
            found_headers.add(matched_header)
            
            # Add each bullet point
            for item in json_data[key]:
                new_lines.append(item + "\n")
            new_lines.append("\n")
            skip_mode = True
            continue
        
        if skip_mode:
            if line.startswith("## "):
                skip_mode = False
            else:
                continue
                
        if not skip_mode:
            new_lines.append(line)

    # Sanity check: ensure we actually found the headers we expected to fill
    missing = set(SECTION_MAPPING.values()) - found_headers
    if missing:
        print(f"Warning: Missing expected headers in note: {missing}", file=sys.stderr)

    with open(note_path, 'w') as f:
        f.writelines(new_lines)

def main():
    if len(sys.argv) < 2:
        print("Usage: fill_note_json.py <note_path>")
        sys.exit(1)

    note_path = sys.argv[1]
    
    # 1. Extract facts from note
    if not os.path.exists(note_path):
        print(f"Note not found: {note_path}")
        sys.exit(1)
        
    with open(note_path, 'r') as f:
        content = f.read()
        
    facts_match = re.search(r'## FACTS\n(.*?)\n## CURRENT_OBSERVATIONS', content, re.DOTALL)
    if not facts_match:
        # Try a more liberal match if possible
        facts_match = re.search(r'## FACTS\n(.*?)\n##', content, re.DOTALL)
        
    if not facts_match:
        print("Error: Could not find ## FACTS block in note.")
        sys.exit(1)
    
    facts = facts_match.group(1).strip()
    
    # 2. Prepare prompt
    prompt = f"""STRICT TASK: You are a code reviewer. Read the facts below for a file.
Output ONLY valid JSON.
DO NOT use Chain of Thought. DO NOT use 'Thinking...' or any preamble.
OUTPUT JSON ONLY.

Required JSON keys:
- "current_observations": [list of strings]
- "possible_overlap": [list of strings]
- "possible_cleanup": [list of strings]
- "needs_cross_check_with": [list of strings]
- "next_action": [list of strings]

Facts:
{facts}

JSON output:"""

    # 3. Model call with retries
    json_data = None
    for attempt in range(MAX_RETRIES + 1):
        if attempt > 0:
            print(f"Retry attempt {attempt}...")
            # Stricter prompt on retry
            prompt += "\nREMINDER: ONLY JSON. NO CONVERSATION. NO MARKDOWN BLOCK WRAPPERS."
            
        raw_output = call_local_model(prompt, attempt=attempt)
        
        parsed_data = extract_json(raw_output)
        if parsed_data:
            json_data = validate_and_normalize_json(parsed_data)
            if json_data:
                break
            
    # 4. Fallback if failed
    if not json_data:
        print("All retries failed or invalid data. Using fallback.")
        json_data = get_fallback_json()
        
    # 5. Apply changes to note
    fill_note(note_path, json_data)
    print(f"Successfully processed note: {note_path}")

if __name__ == "__main__":
    main()
