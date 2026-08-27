---
applyTo: "infra/**,azure.yaml,docs/**/*.md"
---

# Naming and tagging instructions

- Reuse `infra/abbreviations.json` and established Azure Cloud Adoption
  Framework abbreviations; do not invent competing prefixes.
- Derive deterministic uniqueness from subscription, environment, and region.
  Enforce each resource's character, case, global uniqueness, and length rules.
- Use the repository naming contract:
  `rg-`, `appins-`, `law-`, `pe-`, `pe-nic-`, `vnet-`, `snet-`, `nsg-`,
  `bast-`, `vm-win-`, `vm-lin-`, `stacct`, and `kv-`. Storage account names
  must contain only lowercase letters and numbers.
- Prefix subnets with `snet-` except for service-reserved names. Azure Bastion
  must use the exact subnet name `AzureBastionSubnet`.
- Use a stable three-character suffix derived from subscription, environment,
  and region for globally unique resources with short name limits. Do not use
  nondeterministic names that change during repeat deployments.
- Keep `AZURE_ENV_NAME` lowercase, 2–32 characters, alphanumeric/hyphen, starting
  and ending alphanumeric. Do not embed a tenant, subscription, user, email, or
  secret in a resource name.
- Preserve common tags: repository, `azd-env-name`, environment, profile,
  `managed-by`, `created-on`, and `last-updated-on`. Use non-PII team/service
  values for optional owner and cost-center tags.
- Treat names as stable contracts. Renames that replace resources require an
  explicit migration, cost, data-retention, and rollback review.
