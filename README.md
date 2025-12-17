# Workstation Bootstrap

This repository provides a **fully reproducible, Ubuntu 24.04–ready development workstation** and a set of **project scaffolding tools** designed for professional, multi‑stack development (Python, Data, Node/Next.js) with strong security and quality gates.

It is designed to support:
- Fast disaster recovery (new machine → productive in < 1h)
- Strict reproducibility (PEP‑668 safe, no system‑pip pollution)
- GPU‑accelerated ML workloads
- Secure secrets handling (SOPS + age)
- Enforced repo standards (pre‑commit, gitleaks, Conventional Commits)

---

## Repository Structure

```
workstation-bootstrap/
├── bootstrap.sh              # Main workstation installer
├── modules/                  # Modular installers (idempotent)
│   ├── base.sh
│   ├── shell.sh
│   ├── git.sh
│   ├── python.sh
│   ├── node.sh
│   ├── docker.sh
│   ├── gpu.sh
│   ├── secrets.sh
│   ├── hardening.sh
│   ├── backup.sh
│   └── monitoring.sh
├── scripts/
│   ├── verify_workstation.sh # Full environment validation
│   ├── install-dev-hooks.sh  # Husky + commitlint + gitleaks
│   ├── new_project.sh        # Project scaffolder
│   └── disaster_recover.sh   # One-command recovery installer
├── templates/                # Reference templates
├── .github/workflows/        # CI gates
├── .pre-commit-config.yaml
├── .sops.yaml
└── README.md
```

---

## 1. Bootstrapping a New Machine

### Prerequisites
- Ubuntu 24.04 (desktop)
- Internet access
- sudo privileges

### Full install

```bash
cd ~/dev/repos/workstation-bootstrap
./bootstrap.sh
```

The script is **modular and idempotent**. Each module can be toggled via env vars:

```bash
INSTALL_GPU=0 INSTALL_BACKUP=0 ./bootstrap.sh
```

### What gets installed

- **Base**: build tools, CLI utilities, neovim, direnv
- **Shell**: tmux, bash hooks
- **Git**: multi‑identity SSH config
- **Python**: pyenv + pipx + poetry (PEP‑668 compliant)
- **Node**: nvm + LTS + semantic‑release tooling
- **Docker**: Docker + Compose
- **GPU**: NVIDIA drivers + Docker GPU runtime
- **Secrets**: sops + age + gitleaks
- **Hardening**: ufw, fail2ban, unattended upgrades
- **Backup**: restic scaffold
- **Monitoring**: local healthcheck script

Reboot is recommended after GPU + Docker installation.

---

## 2. Verifying the Installation

Run at any time:

```bash
./scripts/verify_workstation.sh
```

This checks:
- PATH correctness
- pyenv / poetry / pipx
- nvm / node / npm
- Docker access and GPU runtime
- Secrets tooling
- Hardening services
- Repo scaffolding integrity

Warnings are non‑blocking; failures indicate required fixes.

---

## 3. Repo‑Level Quality Gates

### Install development hooks

```bash
./scripts/install-dev-hooks.sh
pre-commit install
```

### What is enforced
- **Conventional Commits** (commitlint)
- **Secrets protection** (gitleaks)
- **Code hygiene** (pre‑commit hooks)

Husky is configured so **npm test is NOT required** unless explicitly added by a project.

---

## 4. Creating New Projects (Core Feature)

The repository includes a **single, opinionated scaffolder**.

### Usage

```bash
./scripts/new_project.sh <type> <name> [options]
```

### Supported project types

| Type   | Description |
|------|------------|
| python | Poetry + src layout + ruff/black/pytest + Jupyter |
| next   | Next.js app + semantic‑release stub |
| data   | Python + dbt + optional devstack |

### Common options

| Flag | Effect |
|-----|-------|
| `--init-git` | Initializes git repo and first commit |
| `--with devcontainer` | Adds per‑project DevContainer |
| `--with devstack` | Adds Postgres/Mongo/ClickHouse |
| `--with dbt` | Adds dbt stub |

### Examples

```bash
# Python ML project
./scripts/new_project.sh python ml-service --init-git --with devcontainer

# Next.js dashboard
./scripts/new_project.sh next web-ui --init-git --with devcontainer

# Analytics lab
./scripts/new_project.sh data analytics-lab --init-git
```

---

## 5. Per‑Project DevContainers

When `--with devcontainer` is used:

- `.devcontainer/devcontainer.json` is generated
- Python + Node are preinstalled
- pre‑commit auto‑installs on container create

This allows:
- zero‑setup onboarding
- consistent CI ↔ local parity

---

## 6. Secrets Management (SOPS)

### Principles
- `.env` files are **never committed**
- `.env.enc` files are encrypted with **age**

### Encrypt

```bash
sops --encrypt --output .env.enc .env
```

### Decrypt

```bash
sops --decrypt --output .env .env.enc
```

Age keys are stored locally at:

```
~/.config/sops/age/keys.txt
```

---

## 7. Disaster Recovery (One‑Command Rebuild)

If your machine is wiped or replaced:

```bash
curl -fsSL https://raw.githubusercontent.com/<OWNER>/<REPO>/main/scripts/disaster_recover.sh | \
  BOOTSTRAP_REPO_SSH="git@github.com-work:<OWNER>/<REPO>.git" bash
```

This will:
1. Install git + curl
2. Clone this repo
3. Run `bootstrap.sh`

From zero to productive workstation in one command.

---

## 8. Recommended Workflow

- Use **this repo only for workstation concerns**
- Use `new_project.sh` for all new codebases
- Keep project‑specific logic inside each project
- Re‑run `verify_workstation.sh` after OS updates
- Commit changes to this repo whenever you improve your standards

---

## 9. Philosophy & Design Constraints

- No system Python pollution (PEP‑668)
- User‑scoped tooling via pipx / nvm
- GPU is optional but first‑class
- Everything must be scriptable
- Everything must be reproducible

---

## 10. Next Extensions (Optional)

- Project‑specific CI templates
- Terraform / Cloud tooling modules
- Internal package registries
- Team‑wide bootstrap variants

This repository is intended to evolve alongside your engineering maturity.
