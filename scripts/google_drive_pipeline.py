"""
Google Drive pipeline for recursive listing, conversion, and upload.
"""

from __future__ import annotations

import io
from pathlib import Path
from typing import Dict, List, Optional

import pandas as pd
from googleapiclient.discovery import build
from googleapiclient.http import MediaIoBaseDownload, MediaIoBaseUpload

from document_converters import convert_local_file_to_markdown, markdown_to_docx


def build_drive_service():
    """
    Build an authenticated Google Drive service in Colab or a local OAuth environment.
    """
    try:
        from google.colab import auth
        auth.authenticate_user()
    except Exception:
        pass
    return build("drive", "v3")


def list_files_recursively(service, folder_id: str) -> List[Dict]:
    """
    Recursively list files and folders under a Google Drive folder.
    """
    results: List[Dict] = []
    page_token = None

    while True:
        response = service.files().list(
            q=f"'{folder_id}' in parents and trashed=false",
            spaces="drive",
            fields="nextPageToken, files(id, name, mimeType, parents)",
            pageToken=page_token,
        ).execute()
        for item in response.get("files", []):
            results.append(item)
            if item.get("mimeType") == "application/vnd.google-apps.folder":
                results.extend(list_files_recursively(service, item["id"]))
        page_token = response.get("nextPageToken")
        if not page_token:
            break
    return results


def find_or_create_folder(service, folder_name: str, parent_id: str) -> str:
    """
    Find or create a Google Drive folder under a given parent.
    """
    response = service.files().list(
        q=(
            f"name='{folder_name}' and "
            f"mimeType='application/vnd.google-apps.folder' and "
            f"'{parent_id}' in parents and trashed=false"
        ),
        spaces="drive",
        fields="files(id, name)",
    ).execute()
    files = response.get("files", [])
    if files:
        return files[0]["id"]

    metadata = {
        "name": folder_name,
        "mimeType": "application/vnd.google-apps.folder",
        "parents": [parent_id],
    }
    created = service.files().create(body=metadata, fields="id").execute()
    return created["id"]


def download_drive_file(service, file_id: str, output_path: Path) -> Path:
    """
    Download a binary Google Drive file to a local path.
    """
    output_path = Path(output_path)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    request = service.files().get(fileId=file_id, alt="media")
    with io.FileIO(output_path, "wb") as handle:
        downloader = MediaIoBaseDownload(handle, request)
        done = False
        while not done:
            _, done = downloader.next_chunk()
    return output_path


def export_google_doc_as_text(service, file_id: str) -> str:
    buffer = io.BytesIO()
    request = service.files().export_media(fileId=file_id, mimeType="text/plain")
    downloader = MediaIoBaseDownload(buffer, request)
    done = False
    while not done:
        _, done = downloader.next_chunk()
    buffer.seek(0)
    return buffer.read().decode("utf-8")


def export_google_sheet_as_markdown(service, file_id: str) -> str:
    buffer = io.BytesIO()
    request = service.files().export_media(fileId=file_id, mimeType="text/csv")
    downloader = MediaIoBaseDownload(buffer, request)
    done = False
    while not done:
        _, done = downloader.next_chunk()
    buffer.seek(0)
    frame = pd.read_csv(buffer)
    return frame.to_markdown(index=False)


def upload_text_file(service, parent_folder_id: str, filename: str, content: str, mime_type: str = "text/markdown") -> str:
    media = MediaIoBaseUpload(io.BytesIO(content.encode("utf-8")), mimetype=mime_type, resumable=True)
    metadata = {"name": filename, "parents": [parent_folder_id]}
    created = service.files().create(body=metadata, media_body=media, fields="id").execute()
    return created["id"]


def convert_drive_folder_to_markdown(
    service,
    source_folder_id: str,
    output_folder_id: str,
    temp_dir: Path,
    create_docx: bool = False,
) -> List[Dict]:
    """
    Convert supported Google Drive files to Markdown and optionally DOCX.
    """
    temp_dir = Path(temp_dir)
    temp_dir.mkdir(parents=True, exist_ok=True)
    items = list_files_recursively(service, source_folder_id)
    results: List[Dict] = []

    for item in items:
        mime_type = item.get("mimeType")
        name = item.get("name")
        file_id = item.get("id")

        if mime_type == "application/vnd.google-apps.folder":
            continue

        try:
            if mime_type == "application/vnd.google-apps.document":
                markdown_text = export_google_doc_as_text(service, file_id)
            elif mime_type == "application/vnd.google-apps.spreadsheet":
                markdown_text = export_google_sheet_as_markdown(service, file_id)
            else:
                suffix = Path(name).suffix.lower()
                local_path = temp_dir / f"{file_id}_{name}"
                download_drive_file(service, file_id, local_path)
                markdown_text = convert_local_file_to_markdown(local_path)

            md_name = f"{Path(name).stem}.md"
            upload_text_file(service, output_folder_id, md_name, markdown_text, mime_type="text/markdown")

            if create_docx:
                local_docx = temp_dir / f"{Path(name).stem}.docx"
                markdown_to_docx(markdown_text, local_docx)
                media = MediaIoBaseUpload(io.BytesIO(local_docx.read_bytes()), mimetype="application/vnd.openxmlformats-officedocument.wordprocessingml.document", resumable=True)
                service.files().create(body={"name": local_docx.name, "parents": [output_folder_id]}, media_body=media, fields="id").execute()

            results.append({"file_id": file_id, "name": name, "status": "success"})
        except Exception as exc:
            results.append({"file_id": file_id, "name": name, "status": f"error: {exc}"})

    return results
