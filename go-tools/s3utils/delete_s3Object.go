package s3utils

import (
	"context"
	"errors"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/service/s3"
)

func DeleteS3Object(s3Client *s3.Client, bucketName, fullKey string) error {
	_, err := s3Client.DeleteObject(context.Background(), &s3.DeleteObjectInput{
		Bucket: aws.String(bucketName),
		Key:    aws.String(fullKey),
	})
	if err != nil {
		return errors.New("failed to delete s3utils object: " + err.Error())
	}
	return nil
}
