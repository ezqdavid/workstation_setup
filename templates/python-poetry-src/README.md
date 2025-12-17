# Python Project (Poetry + src/ layout)

## Setup
1) pyenv install 3.11.9
2) pyenv local 3.11.9
3) poetry init / poetry install

## Dev deps (recommended)
poetry add --group dev ruff black pytest jupyterlab

## Commands
- poetry run ruff check .
- poetry run black .
- poetry run pytest
- poetry run jupyter lab
