.PHONY: release help fmt validate lint test

help:
	@echo "Available targets:"
	@echo "  make fmt                    - Format all Terraform files"
	@echo "  make validate               - Validate Terraform configuration (includes all modules)"
	@echo "  make lint                   - Run TFLint on all files"
	@echo "  make test                   - Run fmt, validate, and lint"
	@echo "  make release VERSION=x.y.z  - Create and push a new version tag"

fmt:
	@echo "Formatting Terraform files..."
	@terraform fmt -recursive
	@echo "✓ Formatting complete"

validate:
	@echo "Initializing Terraform..."
	@terraform init -backend=false > /dev/null
	@echo "Validating configuration..."
	@terraform validate
	@echo "✓ Validation complete"

lint:
	@echo "Running TFLint..."
	@tflint --init > /dev/null
	@tflint --recursive
	@echo "✓ Linting complete"

test: fmt validate lint
	@echo "✓ All tests passed"

release:
	@if [ -z "$(VERSION)" ]; then \
		echo "Error: VERSION parameter is required"; \
		exit 1; \
	fi
	@git tag -a v$(VERSION) -m "Release v$(VERSION)"
	@git push origin v$(VERSION)
	@echo "✓ Successfully released v$(VERSION)"
