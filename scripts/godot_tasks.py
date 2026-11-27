#!/usr/bin/env python3
"""Run the existing Godot checks or collect captures in an isolated copy."""

import argparse
from pathlib import Path
import shutil
import subprocess
import tempfile
from dataclasses import dataclass


ROOT = Path(__file__).resolve().parents[1]


@dataclass(frozen=True)
class Check:
    script: str
    result: str
    args: tuple[str, ...] = ()
    fixed_fps: bool = False


CHECKS = {
    "intro": (Check("intro", "INTRO CHECK:", ("--intro-mute",), fixed_fps=True),),
    "deplacements": (Check("movement", "MOVEMENT CHECK:"),),
    "combat": (Check("shooting", "SHOOTING CHECK:"), Check("reload", "RELOAD CHECK:", fixed_fps=True)),
    "carte": (Check("village", "VILLAGE:", fixed_fps=True),),
    "saloon": (Check("saloon_study", "SALOON STUDY:", fixed_fps=True),),
    "sprites": (Check("player_visuals", "PLAYER VISUALS:", fixed_fps=True),
                Check("player_visuals", "PLAYER VISUALS:", ("--warm",), fixed_fps=True)),
    "partie": (Check("match", "MATCH CHECK:", fixed_fps=True),
               Check("bottle_drops", "BOTTLE DROPS:", fixed_fps=True),
               Check("holder_stun", "HOLDER STUN:", fixed_fps=True),
               Check("v02", "V02 CHECK:", fixed_fps=True),
               Check("v03", "V03 CHECK:", fixed_fps=True),
               Check("v03_review", "V03 REVIEW:", fixed_fps=True)),
}


def run_godot(command, log, timeout, expected_result=""):
    print(f"{log.stem}…", flush=True)
    with log.open("w", encoding="utf-8") as stream:
        try:
            result = subprocess.run(command, stdout=stream, stderr=subprocess.STDOUT,
                                    timeout=timeout)
        except subprocess.TimeoutExpired:
            print(f"  ÉCHEC · délai de {timeout} s dépassé · {log}")
            return False

    lines = log.read_text(encoding="utf-8", errors="replace").splitlines()
    report = next((line for line in reversed(lines) if expected_result and
                   line.startswith(expected_result)), "")
    errors = [line for line in lines if line.startswith(("ERROR:", "SCRIPT ERROR:"))
              and not environment_error(line)]
    missing_report = expected_result and not report
    if result.returncode or errors or missing_report:
        reason = f"code {result.returncode}" if result.returncode else (
            "erreur Godot" if errors else "résultat du contrôle absent")
        print(f"  ÉCHEC · {reason} · {log}")
        for line in (errors or lines[-5:])[:5]:
            print(f"  {line}")
        return False

    print(f"  {report or 'OK'}")
    return True


def environment_error(line):
    # The desktop sandbox restricts these macOS services even on a valid import.
    return (line == 'ERROR: Condition "ret != noErr" is true. Returning: ""'
            or line.startswith(("ERROR: Cannot save file '", "ERROR: Error saving editor settings to "))
            and "/Application Support/Godot/editor_settings-" in line)


def main():
    parser = argparse.ArgumentParser(description="Vérifier le jeu ou produire des captures Godot.")
    parser.add_argument("mode", choices=("verifier", "capturer"))
    parser.add_argument("sujets", nargs="*", metavar="SUJET",
                        help=f"{', '.join(CHECKS)}. Sans sujet, exécute tout.")
    parser.add_argument("--godot", default="godot", help="Chemin de l’exécutable Godot.")
    parser.add_argument("--output", type=Path, default=ROOT / "tmp" / "godot-runs",
                        help="Dossier parent des résultats, par défaut tmp/godot-runs.")
    parser.add_argument("--timeout", type=int, default=120, help="Délai par étape, en secondes.")
    args = parser.parse_args()
    if args.timeout < 1:
        parser.error("--timeout doit être positif.")
    unknown = set(args.sujets) - CHECKS.keys()
    if unknown:
        parser.error(f"Sujet inconnu : {', '.join(sorted(unknown))}. Choix : {', '.join(CHECKS)}.")
    godot = shutil.which(args.godot)
    if not godot:
        parser.error("Godot est introuvable. Ajoute-le au PATH ou indique son chemin avec --godot.")

    output = args.output.expanduser().resolve()
    source = ROOT / "godot"
    if output == source or source in output.parents:
        parser.error("Indique un dossier de résultats en dehors du projet Godot.")
    output.mkdir(parents=True, exist_ok=True)
    run = Path(tempfile.mkdtemp(prefix=f"{args.mode}-", dir=output))
    print(f"Résultats : {run}", flush=True)
    project = run / "godot"
    logs = run / "logs"
    logs.mkdir()
    base = [godot, "--path", str(project), "--log-file", str(project / "engine.log")]
    render = args.mode == "capturer"

    try:
        shutil.copytree(source, project, ignore=shutil.ignore_patterns(
            ".godot", "builds", "export_credentials.cfg", ".DS_Store"))
        if not run_godot(base + ["--headless", "--import"], logs / "import.log", args.timeout):
            return 1
        failed = 0
        captures = set()
        for subject in dict.fromkeys(args.sujets or CHECKS):
            for check in CHECKS[subject]:
                options = ["--audio-driver", "Dummy"] if render else ["--headless"]
                if check.fixed_fps:
                    options += ["--fixed-fps", "60"]
                if render and subject == "intro":
                    options += ["--resolution", "640x360"]
                name = check.script + ("-warm" if "--warm" in check.args else "")
                command = base + options + ["--script", f"res://tools/verify_{check.script}.gd"]
                if check.args:
                    command += ["--", *check.args]
                passed = run_godot(command, logs / f"{name}.log", args.timeout, check.result)
                if not passed:
                    failed += 1
                if render:
                    produced = set((run / "output").rglob("*.png"))
                    if passed and not produced - captures:
                        print(f"  ÉCHEC · aucune nouvelle capture pour {name}")
                        failed += 1
                    captures = produced
        if render:
            print(f"{len(captures)} capture(s) produites · résultats : {run / 'output'}")
        print(f"{failed} étape(s) en échec · journaux : {logs}")
        return int(failed > 0)
    finally:
        if project.exists():
            shutil.rmtree(project)


if __name__ == "__main__":
    raise SystemExit(main())
