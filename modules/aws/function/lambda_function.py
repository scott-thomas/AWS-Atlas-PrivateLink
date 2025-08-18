import os
import pymongo
from pymongo.errors import ConnectionFailure, OperationFailure
import json
import boto3
from botocore.exceptions import NoCredentialsError, PartialCredentialsError

def lambda_handler(event, context):
    """
    AWS Lambda function to check connectivity to MongoDB Atlas via a VPC endpoint using IAM authentication.

    Args:
        event (dict): The event dict from Lambda. Not used in this example but required.
        context (object): The context object from Lambda. Not used in this example but required.

    Returns:
        dict: A dictionary containing the status of the MongoDB connection.
    """
    
    # Get the Atlas private connection string from environment variable
    # This should be set from Terraform using: 
    # data.mongodbatlas_cluster.your_cluster.connection_strings[0].private_endpoint[0].connection_string
    mongodb_uri = os.environ.get("MONGODB_URI")
    database_name = os.environ.get("MONGODB_DATABASE", "my_new_database")
    
    if not mongodb_uri:
        print("Error: ATLAS_CONNECTION_STRING environment variable is not set.")
        return {
            'statusCode': 500,
            'body': json.dumps('Error: ATLAS_CONNECTION_STRING environment variable is not set.')
        }

    client = None
    try:
        print(f"Attempting to connect to MongoDB Atlas using private endpoint...")
        print(f"Database: {database_name}")
        
        # Verify AWS credentials are available
        try:
            session = boto3.Session()
            credentials = session.get_credentials()
            if not credentials:
                raise NoCredentialsError()
            print("AWS credentials successfully retrieved from Lambda execution role")
        except (NoCredentialsError, PartialCredentialsError) as e:
            print(f"AWS credentials error: {e}")
            return {
                'statusCode': 500,
                'body': json.dumps(f'AWS credentials error: {e}')
            }

        # Connect to MongoDB Atlas using IAM authentication
        client = pymongo.MongoClient(
            mongodb_uri,
            authSource='$external',             # Required for IAM authentication
            authMechanism='MONGODB-AWS',        # Use AWS IAM for authentication
            connectTimeoutMS=30000,             # 30 seconds to establish initial connection
            serverSelectionTimeoutMS=30000,     # 30 seconds to find a server
            socketTimeoutMS=30000,              # 30 seconds for socket operations
            maxPoolSize=1,                      # Limit connection pool for Lambda
            retryWrites=True
        )

        # Test the connection with ping
        result = client.admin.command('ping')
        print(f"Successfully connected to MongoDB Atlas! Ping result: {result}")

        # Test database access
        db = client[database_name]
        
        # Try to list collections to verify database access
        try:
            collections = db.list_collection_names()
            print(f"Successfully accessed database '{database_name}'. Collections: {collections}")
            
            # Optional: Test a simple write/read operation
            test_collection = db['test_connection']
            test_doc = {"test": "connection", "timestamp": context.aws_request_id}
            insert_result = test_collection.insert_one(test_doc)
            print(f"Test document inserted with ID: {insert_result.inserted_id}")
            
            # Read it back
            retrieved_doc = test_collection.find_one({"_id": insert_result.inserted_id})
            print(f"Test document retrieved: {retrieved_doc}")
            
            # Clean up test document
            test_collection.delete_one({"_id": insert_result.inserted_id})
            print("Test document cleaned up")
            
        except OperationFailure as db_error:
            print(f"Database operation failed: {db_error}")
            return {
                'statusCode': 500,
                'body': json.dumps(f'Database access failed: {db_error}')
            }

        return {
            'statusCode': 200,
            'body': json.dumps('Successfully connected to MongoDB Atlas and performed database operations.')
        }

    except ConnectionFailure as e:
        print(f"MongoDB connection error: {e}")
        return {
            'statusCode': 500,
            'body': json.dumps(f'MongoDB connection error: {e}')
        }
    except Exception as e:
        print(f"An unexpected error occurred: {e}")
        return {
            'statusCode': 500,
            'body': json.dumps(f'An unexpected error occurred: {e}')
        }
    finally:
        if client:
            client.close()
            print("MongoDB client closed.")