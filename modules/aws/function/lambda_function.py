import os
import pymongo
from pymongo.errors import ConnectionFailure, OperationFailure
import json
import boto3
from botocore.exceptions import NoCredentialsError, PartialCredentialsError
from bson.json_util import dumps

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
    # For the sample_mflix dataset, use the correct database and collection
    database_name = os.environ.get("MONGODB_DATABASE", "sample_mflix")
    
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

        # Access the sample_mflix.movies collection and return collection info and a sample of movies
        db = client[database_name]
        try:
            collections = db.list_collection_names()
            print(f"Collections in database '{database_name}': {collections}")
            movies_collection = db["movies"]
            doc_count = movies_collection.count_documents({})
            print(f"sample_mflix.movies document count: {doc_count}")
            # Limit to 5 movies for debug
            movies_cursor = movies_collection.find().limit(5)
            movies = list(movies_cursor)
            print(f"Returning {len(movies)} sample movies from sample_mflix.movies.")
            return {
                'statusCode': 200,
                'body': dumps({
                    'collections': collections,
                    'movies_count': doc_count,
                    'sample_movies': movies
                })
            }
        except OperationFailure as db_error:
            print(f"Database operation failed: {db_error}")
            return {
                'statusCode': 500,
                'body': json.dumps(f'Database access failed: {db_error}')
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