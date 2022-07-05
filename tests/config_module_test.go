package test

import (
	"testing"

	// "github.com/aws/aws-sdk-go/aws/credentials"
	// "github.com/aws/aws-sdk-go/aws/session"
	// "github.com/aws/aws-sdk-go/service/iam"
	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/terraform"
	// "github.com/stretchr/testify/assert"
	// awssdk "github.com/aws/aws-sdk-go/aws"
)

func TestConfigModuleHappyPath(t *testing.T) {
	t.Parallel()
	const terraformDir = "../config"

	awsRegion := aws.GetRandomStableRegion(t, []string{allowedRegion}, nil)
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: terraformDir,
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
	})

	t.Run("happy_path", func(t *testing.T) {
		defer terraform.Destroy(t, terraformOptions)
		terraform.InitAndApply(t, terraformOptions)
	})
}
