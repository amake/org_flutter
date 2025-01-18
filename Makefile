git_hash = $(shell git rev-parse --short HEAD)
gold_dir = $(PWD)/tmp/$(git_hash)

.PHONY: test
test: ## Run all tests
test: test-unit test-example

.PHONY: test-unit
test-unit: ## Run unit tests
	flutter test

.PHONY: test-example
test-example: ## Run example tests
	cd example && flutter test

.PHONY: screenshot
screenshot: ## Manually dump screenshots for layout testing purposes
	rm -rf $(gold_dir)
	flutter test --dart-define=GOLD_DIR=$(gold_dir) --plain-name 'Screenshot' --update-goldens --run-skipped
# Screenshot of entire document is so big that most viewers can't handle it, so
# we split it into 20 parts
	cd $(gold_dir) && for f in *.png; do convert -crop 1x20@ +repage $$f $${f%%.png}-%d.png; done

.PHONY: help
help: ## Show this help text
	$(info usage: make [target])
	$(info )
	$(info Available targets:)
	@awk -F ':.*?## *' '/^[^\t].+?:.*?##/ \
         {printf "  %-24s %s\n", $$1, $$2}' $(MAKEFILE_LIST)
