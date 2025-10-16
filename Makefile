.PHONY: release help

help:
	@echo "Available targets:"
	@echo "  make release VERSION=x.y.z  - Create and push a new version tag"

release:
	@if [ -z "$(VERSION)" ]; then \
		echo "Error: VERSION parameter is required"; \
		exit 1; \
	fi
	@git tag -a v$(VERSION) -m "Release v$(VERSION)"
	@git push origin v$(VERSION)
	@echo "✓ Successfully released v$(VERSION)"
