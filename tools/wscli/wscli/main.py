from __future__ import annotations

import os
import subprocess
from pathlib import Path
from typing import Optional

import typer
from rich.console import Console
from rich.panel import Panel
from rich.prompt import Confirm, Prompt

app = typer.Typer(no_args_is_help=True, add_completion=False)
console = Console()

REPO_ROOT = Path(__file__).resolve().parents[2]  # .../tools/wscli
BOOTSTRAP_REPO = REPO_ROOT.parent  # .../workstation-bootstrap


def _run(cmd: list[str], cwd: Optional[Path] = None) -> None:
    console.print(f"[bold cyan]$[/] {' '.join(cmd)}")
    subprocess.run(cmd, cwd=str(cwd) if cwd else None, check=True)


def _default_repos_dir() -> Path:
    return Path(os.environ.get("WS_REPOS_DIR", str(Path.home() / "dev" / "repos")))


@app.command()
def doctor() -> None:
    """
    Run workstation verification report.
    """
    verifier = BOOTSTRAP_REPO / "scripts" / "verify_workstation.sh"
    if not verifier.exists():
        raise typer.Exit(code=2)
    console.print(Panel.fit("Running workstation verification...", title="ws doctor"))
    _run([str(verifier)])


@app.command()
def new(
    project_type: Optional[str] = typer.Argument(None, help="python | next | data"),
    name: Optional[str] = typer.Argument(None, help="Project folder name"),
    repos_dir: Path = typer.Option(None, "--dir", help="Base directory for repos"),
    devcontainer: Optional[bool] = typer.Option(None, "--devcontainer/--no-devcontainer"),
    devstack: Optional[bool] = typer.Option(None, "--devstack/--no-devstack"),
    dbt: Optional[bool] = typer.Option(None, "--dbt/--no-dbt"),
    init_git: Optional[bool] = typer.Option(None, "--git/--no-git"),
    no_hooks: bool = typer.Option(False, "--no-hooks", help="Do not install pre-commit hooks"),
) -> None:
    """
    Interactive project scaffolder (wraps scripts/new_project.sh).
    """
    scaffold = BOOTSTRAP_REPO / "scripts" / "new_project.sh"
    if not scaffold.exists():
        console.print("[red]Missing scripts/new_project.sh in bootstrap repo.[/]")
        raise typer.Exit(code=2)

    console.print(Panel.fit("Interactive project creator", title="ws new"))

    pt = project_type or Prompt.ask(
        "Project type", choices=["python", "next", "data"], default="python"
    )
    nm = name or Prompt.ask("Project name (folder)", default="my-project")

    base = repos_dir or _default_repos_dir()
    base_str = str(base)

    # Interactive defaults
    if devcontainer is None:
        devcontainer = Confirm.ask("Add DevContainer?", default=True)
    if devstack is None:
        devstack = Confirm.ask("Add devstack (postgres/mongo/clickhouse)?", default=(pt in ["data"]))
    if dbt is None:
        dbt = Confirm.ask("Add dbt stub?", default=(pt in ["data"]))
    if init_git is None:
        init_git = Confirm.ask("Init git repo?", default=True)

    args = [str(scaffold), pt, nm, "--dir", base_str]
    if init_git:
        args.append("--init-git")
    if no_hooks:
        args.append("--no-hooks")
    if devcontainer:
        args += ["--with", "devcontainer"]
    if devstack:
        args += ["--with", "devstack"]
    if dbt:
        args += ["--with", "dbt"]

    summary = "\n".join(
        [
            f"[bold]Type[/]: {pt}",
            f"[bold]Name[/]: {nm}",
            f"[bold]Dir[/]: {base_str}",
            f"[bold]DevContainer[/]: {devcontainer}",
            f"[bold]Devstack[/]: {devstack}",
            f"[bold]dbt[/]: {dbt}",
            f"[bold]Init git[/]: {init_git}",
            f"[bold]Install hooks[/]: {not no_hooks}",
        ]
    )
    console.print(Panel(summary, title="Plan", subtitle="Confirm to execute"))

    if not Confirm.ask("Proceed?", default=True):
        console.print("[yellow]Cancelled.[/]")
        raise typer.Exit(code=0)

    _run(args, cwd=BOOTSTRAP_REPO)
    console.print("[green]Done.[/]")


if __name__ == "__main__":
    app()
