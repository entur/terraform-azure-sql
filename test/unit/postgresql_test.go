//go:build unit

package postgres

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestUT_Postgresql(t *testing.T) {
	t.Parallel()

	tfOptions := &terraform.Options{
		TerraformDir: "../../examples/postgresql-test",
		NoColor:      true,
		Logger:       logger.Discard,
		PlanFilePath: "plan.out",
	}

	plan := terraform.InitAndPlanAndShowWithStruct(t, tfOptions)

	terraform.RequireResourceChangesMapKeyExists(t, plan, "module.postgresql.azurerm_postgresql_server.main")
}
