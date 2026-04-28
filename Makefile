PYTHON ?= python3
VENV   ?= .venv

.PHONY: help venv sprites build run clean

help:
	@echo "targets:"
	@echo "  venv     - create .venv and install Python deps"
	@echo "  sprites  - slice sprite sheet & remove background (rembg)"
	@echo "  build    - compile Swift sources and assemble Marin.app"
	@echo "  run      - launch Marin.app"
	@echo "  clean    - remove build artifacts (keeps sprites)"

venv:
	$(PYTHON) -m venv $(VENV)
	$(VENV)/bin/pip install --upgrade pip
	$(VENV)/bin/pip install -r requirements.txt

sprites:
	@if [ -x $(VENV)/bin/python ]; then \
		$(VENV)/bin/python scripts/slice_sprites.py; \
	else \
		$(PYTHON) scripts/slice_sprites.py; \
	fi

build:
	bash scripts/build_app.sh

run:
	open Marin.app

clean:
	rm -rf build Marin.app
