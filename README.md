# Terraform modules for SQL servers on Azure

## PostgreSQL single server
[Module](modules/postgresql)

[Examples](examples/postgresql)

## PostgreSQL flexible server
[Module](modules/postgresql-flex)

[Examples](examples/postgresql-flex)

## Getting started

<!-- ci: x-release-please-start-version -->
### Example using the latest release of the Standard Server module
```
module "postgresql" {
  source = "github.com/entur/terraform-azure-sql//modules/postgresql?ref=v0.1.0"
  ...
}
```
<!-- ci: x-release-please-end -->

See the `README.md` under each module's subfolder for a list of supported inputs and outputs. For examples showing how they're implemented, check the [examples](examples) subfolder.

### Version constraints
You can control the version of a module dependency by adding `?ref=TAG` at the end of the source argument, as shown in the example above. This is highly recommended. You can find a list of available versions [here](https://github.com/entur/terraform-google-sql/releases).

Dependency automation tools such as Renovate Bot will be able to discover new releases and suggest updates automatically.
