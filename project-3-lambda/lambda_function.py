def lambda_handler(event, context):
    file_name = event['Records'][0]['s3']['object']['key']
    bucket_name = event['Records'][0]['s3']['bucket']['name']
    
    print(f"New file uploaded: {file_name} in bucket: {bucket_name}")
    
    return {
        'statusCode': 200,
        'body': f'Successfully processed {file_name}'
    }