package s3utils

import (
	"context"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/aws/aws-sdk-go-v2/service/s3/types"
	"log"
)

func WipeS3Bucket(s3Client *s3.Client, bucketName string) error {
	ctx := context.Background()

	// Step 1: List all objects
	listInput := &s3.ListObjectsV2Input{
		Bucket: aws.String(bucketName),
	}

	paginator := s3.NewListObjectsV2Paginator(s3Client, listInput)

	for paginator.HasMorePages() {
		page, err := paginator.NextPage(ctx)
		if err != nil {
			return err
		}

		if len(page.Contents) == 0 {
			log.Println("Bucket is already empty.")
			return nil
		}

		// Step 2: Build delete request
		objectsToDelete := make([]types.ObjectIdentifier, len(page.Contents))
		for i, obj := range page.Contents {
			objectsToDelete[i] = types.ObjectIdentifier{Key: obj.Key}
		}

		// Step 3: Delete the objects
		_, err = s3Client.DeleteObjects(ctx, &s3.DeleteObjectsInput{
			Bucket: aws.String(bucketName),
			Delete: &types.Delete{
				Objects: objectsToDelete,
				Quiet:   aws.Bool(true),
			},
		})

		if err != nil {
			return err
		}
		log.Printf("Deleted %d objects from bucket '%s'\n", len(objectsToDelete), bucketName)
	}

	return nil
}
