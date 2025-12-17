.PHONY: help bootstrap check

help:
	@echo "Targets:"
	@echo "  make bootstrap   Run full bootstrap"
	@echo "  make check       Run repo checks (pre-commit if installed)"

bootstrap:
	./bootstrap.sh

check:
	@if command -v pre-commit >/dev/null 2>&1; then pre-commit run -a; else echo "pre-commit not installed"; fi
