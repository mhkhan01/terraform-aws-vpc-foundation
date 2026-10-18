EXAMPLES := examples/dev examples/prod
MODULES  := modules/vpc

.PHONY: all fmt validate lint test security docs

all: fmt validate lint test security docs

fmt:
	terraform fmt -recursive

validate:
	@for d in $(EXAMPLES); do \
		echo "==> validate $$d"; \
		(cd $$d && terraform init -backend=false -input=false >/dev/null && terraform validate) || exit 1; \
	done

lint:
	tflint --init
	tflint --recursive --format compact

test:
	@for d in $(EXAMPLES); do \
		echo "==> test $$d"; \
		(cd $$d && terraform init -backend=false -input=false >/dev/null && terraform test) || exit 1; \
	done

security:
	checkov -d . --config-file .checkov.yaml --quiet

docs:
	@for m in $(MODULES); do \
		terraform-docs markdown table --output-file README.md --output-mode inject $$m; \
	done
