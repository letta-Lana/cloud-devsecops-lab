import functions_framework

@functions_framework.cloud_event
def process_upload(cloud_event):
    file_name = cloud_event.data["name"]
    bucket_name = cloud_event.data["bucket"]

    if file_name.endswith(".txt") or file_name.endswith(".html"):
        print(f"New file uploaded: {file_name} in bucket: {bucket_name}")
    else:
        print(f"Unsupported file type uploaded: {file_name}")