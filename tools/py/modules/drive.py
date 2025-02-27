from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build
from googleapiclient.http import MediaIoBaseDownload
import io
import os

def main(action, *args):
    if action == "download":
        file_id = args[0]
        api_key = os.environ.get("GOOGLE_DRIVE_API_KEY")
        creds = Credentials.from_authorized_user_info({"api_key": 
api_key})
        service = build("drive", "v3", credentials=creds)
        request = service.files().get_media(fileId=file_id)
        fh = io.FileIO(f"downloaded_{file_id}", "wb")
        downloader = MediaIoBaseDownload(fh, request)
        done = False
        while not done:
            status, done = downloader.next_chunk()
        return f"Downloaded file {file_id} from Google Drive"
    return "Unknown action"
