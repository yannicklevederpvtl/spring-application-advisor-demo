#!/usr/bin/env python3
"""Generate Excalidraw-style architecture diagrams for the demo repo."""

from __future__ import annotations

import json
import random
import uuid
from pathlib import Path

ASSETS = Path(__file__).resolve().parent.parent / "assets"
FONT = "Excalifont, Xiaolai, Segoe UI Emoji, sans-serif"
STROKE = "#1e1e1e"


def _id() -> str:
    return uuid.uuid4().hex[:16]


def _seed() -> int:
    return random.randint(100000, 999999999)


def rect(x, y, w, h, text, bg="#ffffff", stroke=STROKE, dashed=False):
    rid = _id()
    tid = _id()
    elements = [
        {
            "id": rid,
            "type": "rectangle",
            "x": x,
            "y": y,
            "width": w,
            "height": h,
            "angle": 0,
            "strokeColor": stroke,
            "backgroundColor": bg,
            "fillStyle": "solid",
            "strokeWidth": 2,
            "strokeStyle": "dashed" if dashed else "solid",
            "roughness": 1,
            "opacity": 100,
            "groupIds": [],
            "frameId": None,
            "roundness": {"type": 3},
            "seed": _seed(),
            "version": 1,
            "versionNonce": _seed(),
            "isDeleted": False,
            "boundElements": [{"type": "text", "id": tid}],
            "updated": 1,
            "link": None,
            "locked": False,
        },
        {
            "id": tid,
            "type": "text",
            "x": x + 12,
            "y": y + h / 2 - 10,
            "width": w - 24,
            "height": 25,
            "angle": 0,
            "strokeColor": stroke,
            "backgroundColor": "transparent",
            "fillStyle": "solid",
            "strokeWidth": 1,
            "strokeStyle": "solid",
            "roughness": 1,
            "opacity": 100,
            "groupIds": [],
            "frameId": None,
            "roundness": None,
            "seed": _seed(),
            "version": 1,
            "versionNonce": _seed(),
            "isDeleted": False,
            "boundElements": [],
            "updated": 1,
            "link": None,
            "locked": False,
            "text": text,
            "fontSize": 16,
            "fontFamily": 5,
            "textAlign": "center",
            "verticalAlign": "middle",
            "containerId": rid,
            "originalText": text,
            "lineHeight": 1.25,
        },
    ]
    return elements, rid


def label(x, y, text, size=20, color=STROKE):
    return {
        "id": _id(),
        "type": "text",
        "x": x,
        "y": y,
        "width": 600,
        "height": 30,
        "angle": 0,
        "strokeColor": color,
        "backgroundColor": "transparent",
        "fillStyle": "solid",
        "strokeWidth": 1,
        "strokeStyle": "solid",
        "roughness": 1,
        "opacity": 100,
        "groupIds": [],
        "frameId": None,
        "roundness": None,
        "seed": _seed(),
        "version": 1,
        "versionNonce": _seed(),
        "isDeleted": False,
        "boundElements": [],
        "updated": 1,
        "link": None,
        "locked": False,
        "text": text,
        "fontSize": size,
        "fontFamily": 5,
        "textAlign": "left",
        "verticalAlign": "top",
        "containerId": None,
        "originalText": text,
        "lineHeight": 1.25,
    }


def arrow(x1, y1, x2, y2, text="", dashed=False):
    w = x2 - x1
    h = y2 - y1
    el = {
        "id": _id(),
        "type": "arrow",
        "x": x1,
        "y": y1,
        "width": w,
        "height": h,
        "angle": 0,
        "strokeColor": STROKE,
        "backgroundColor": "transparent",
        "fillStyle": "solid",
        "strokeWidth": 2,
        "strokeStyle": "dashed" if dashed else "solid",
        "roughness": 1,
        "opacity": 100,
        "groupIds": [],
        "frameId": None,
        "roundness": {"type": 2},
        "seed": _seed(),
        "version": 1,
        "versionNonce": _seed(),
        "isDeleted": False,
        "boundElements": [],
        "updated": 1,
        "link": None,
        "locked": False,
        "points": [[0, 0], [w, h]],
        "lastCommittedPoint": None,
        "startBinding": None,
        "endBinding": None,
        "startArrowhead": None,
        "endArrowhead": "arrow",
    }
    if text:
        el["boundElements"] = []
    return el


def zone(x, y, w, h, text):
    rid = _id()
    return [
        {
            "id": rid,
            "type": "rectangle",
            "x": x,
            "y": y,
            "width": w,
            "height": h,
            "angle": 0,
            "strokeColor": "#868e96",
            "backgroundColor": "#e9ecef",
            "fillStyle": "solid",
            "strokeWidth": 1,
            "strokeStyle": "dashed",
            "roughness": 1,
            "opacity": 100,
            "groupIds": [],
            "frameId": None,
            "roundness": {"type": 3},
            "seed": _seed(),
            "version": 1,
            "versionNonce": _seed(),
            "isDeleted": False,
            "boundElements": [],
            "updated": 1,
            "link": None,
            "locked": False,
        },
        label(x + 16, y + 12, text, size=18, color="#868e96"),
    ]


def build_minimal() -> list:
    els: list = []
    els.extend(zone(20, 50, 920, 420, "Developer machine — Minimal setup (no Docker)"))
    els.append(label(40, 10, "Spring Application Advisor Demo — Minimal", size=24))

    for part, rid in [
        rect(60, 120, 170, 72, "spring-petclinic\n(advisor-demo)", "#b2f2bb"),
        rect(280, 110, 210, 92, "Application Advisor\nCLI 1.6.3", "#b2f2bb"),
        rect(540, 90, 260, 72, "demo/mappings/\nacme-spring-commons.json", "#eebefa"),
        rect(540, 190, 260, 72, "demo/local-repo\nacme 1.0 / 2.0 / 3.0", "#99e9f2"),
        rect(60, 260, 170, 64, "~/.m2/settings.xml", "#ffffff"),
        rect(280, 250, 160, 64, "Maven Central", "#a5d8ff"),
        rect(480, 250, 240, 64, "packages.broadcom.com\n(Spring Enterprise)", "#a5d8ff"),
        rect(60, 380, 120, 56, "IDE", "#ffffff"),
        rect(220, 380, 150, 56, "advisor mcp\n(stdio)", "#ffd8a8"),
    ]:
        els.extend(part)

    els.append(label(400, 390, "No Application Advisor Server", size=14, color="#868e96"))
    els.append(arrow(230, 156, 280, 156))
    els.append(arrow(490, 146, 540, 126))
    els.append(arrow(390, 202, 540, 220))
    els.append(arrow(145, 192, 145, 260))
    els.append(arrow(230, 282, 280, 282))
    els.append(arrow(440, 282, 480, 282))
    els.append(arrow(180, 408, 220, 408, dashed=True))
    return els


def build_enterprise() -> list:
    els: list = []
    els.extend(zone(20, 50, 960, 500, "Developer machine — Enterprise lab"))
    els.append(label(40, 10, "Spring Application Advisor Demo — Enterprise lab", size=24))

    for part in [
        rect(60, 120, 170, 72, "spring-petclinic\n(advisor-demo)", "#b2f2bb"),
        rect(280, 110, 210, 92, "Application Advisor\nCLI 1.6.3", "#b2f2bb"),
        rect(540, 100, 260, 64, "demo/mappings/\nacme-spring-commons.json", "#eebefa"),
        rect(60, 240, 170, 64, "~/.m2/settings.xml", "#ffffff"),
        rect(280, 230, 180, 64, "Artifactory :8082", "#ffd8a8"),
        rect(500, 220, 200, 64, "maven-virtual-repo", "#ffd8a8"),
        rect(280, 330, 160, 56, "maven-remote-repo\n→ Maven Central", "#a5d8ff"),
        rect(480, 330, 220, 56, "spring-enterprise-mvn-remote\n→ packages.broadcom.com", "#a5d8ff"),
        rect(740, 330, 160, 56, "maven-local-repo", "#a5d8ff"),
        rect(740, 230, 160, 64, "PostgreSQL", "#99e9f2"),
        rect(60, 430, 200, 72, "Git server :2222\n(optional)", "#e9ecef", dashed=True),
    ]:
        els.extend(part)

    els.append(label(400, 420, "Mappings loaded by CLI — no Advisor Server (port 9003 removed)", size=14, color="#868e96"))
    els.append(arrow(230, 156, 280, 156))
    els.append(arrow(490, 132, 540, 132))
    els.append(arrow(145, 192, 145, 240))
    els.append(arrow(230, 272, 280, 262))
    els.append(arrow(460, 262, 500, 252))
    els.append(arrow(560, 284, 560, 330))
    els.append(arrow(420, 358, 480, 358))
    els.append(arrow(700, 358, 740, 358))
    els.append(arrow(820, 294, 820, 330))
    els.append(arrow(820, 230, 820, 294))
    els.append(arrow(145, 192, 145, 430, dashed=True))
    return els


def write_excalidraw(path: Path, elements: list) -> None:
    doc = {
        "type": "excalidraw",
        "version": 2,
        "source": "spring-application-advisor-demo/scripts/generate-diagrams.py",
        "elements": elements,
        "appState": {
            "viewBackgroundColor": "#ffffff",
            "gridSize": 20,
        },
        "files": {},
    }
    path.write_text(json.dumps(doc, indent=2), encoding="utf-8")


def sketch_rect(x, y, w, h, bg, dashed=False):
    dash = ' stroke-dasharray="8 6"' if dashed else ""
    return (
        f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="8" ry="8" '
        f'fill="{bg}" stroke="{STROKE}" stroke-width="2"{dash}/>'
    )


def svg_text(x, y, text, size=16, anchor="middle", weight="normal"):
    lines = text.split("\n")
    if len(lines) == 1:
        return (
            f'<text x="{x}" y="{y}" font-family="{FONT}" font-size="{size}px" '
            f'fill="{STROKE}" text-anchor="{anchor}" font-weight="{weight}">{text}</text>'
        )
    out = [f'<text font-family="{FONT}" font-size="{size}px" fill="{STROKE}" text-anchor="{anchor}">']
    for i, line in enumerate(lines):
        dy = 0 if i == 0 else 20
        out.append(f'<tspan x="{x}" y="{y + i * 20}" dy="{dy}">{line}</tspan>')
    out.append("</text>")
    return "\n".join(out)


def svg_arrow(x1, y1, x2, y2, dashed=False):
    dash = ' stroke-dasharray="8 6"' if dashed else ""
    return (
        f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" stroke="{STROKE}" '
        f'stroke-width="2" marker-end="url(#arrowhead)"{dash}/>'
    )


def write_svg_minimal(path: Path) -> None:
    w, h = 980, 520
    parts = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">',
        "<defs><marker id=\"arrowhead\" markerWidth=\"10\" markerHeight=\"7\" refX=\"9\" refY=\"3.5\" orient=\"auto\">"
        f'<polygon points="0 0, 10 3.5, 0 7" fill="{STROKE}"/></marker></defs>',
        f'<rect width="{w}" height="{h}" fill="#ffffff"/>',
        sketch_rect(20, 50, 920, 420, "#e9ecef", dashed=True),
        svg_text(40, 35, "Spring Application Advisor Demo — Minimal", 24, "start", "bold"),
        svg_text(36, 72, "Developer machine — Minimal setup (no Docker)", 18, "start"),
        sketch_rect(60, 120, 170, 72, "#b2f2bb"),
        svg_text(145, 160, "spring-petclinic\n(advisor-demo)", 15),
        sketch_rect(280, 110, 210, 92, "#b2f2bb"),
        svg_text(385, 160, "Application Advisor\nCLI 1.6.3", 15),
        sketch_rect(540, 90, 260, 72, "#eebefa"),
        svg_text(670, 130, "demo/mappings/\nacme-spring-commons.json", 14),
        sketch_rect(540, 190, 260, 72, "#99e9f2"),
        svg_text(670, 230, "demo/local-repo\nacme 1.0 / 2.0 / 3.0", 14),
        sketch_rect(60, 260, 170, 64, "#ffffff"),
        svg_text(145, 295, "~/.m2/settings.xml", 14),
        sketch_rect(280, 250, 160, 64, "#a5d8ff"),
        svg_text(360, 285, "Maven Central", 14),
        sketch_rect(480, 250, 240, 64, "#a5d8ff"),
        svg_text(600, 275, "packages.broadcom.com\n(Spring Enterprise)", 14),
        sketch_rect(60, 380, 120, 56, "#ffffff"),
        svg_text(120, 412, "IDE", 14),
        sketch_rect(220, 380, 150, 56, "#ffd8a8"),
        svg_text(295, 412, "advisor mcp\n(stdio)", 14),
        svg_text(400, 410, "No Application Advisor Server", 14, "start"),
        svg_arrow(230, 156, 280, 156),
        svg_arrow(490, 146, 540, 126),
        svg_arrow(390, 202, 540, 220),
        svg_arrow(145, 192, 145, 260),
        svg_arrow(230, 282, 280, 282),
        svg_arrow(440, 282, 480, 282),
        svg_arrow(180, 408, 220, 408, dashed=True),
        "</svg>",
    ]
    path.write_text("\n".join(parts), encoding="utf-8")


def write_svg_enterprise(path: Path) -> None:
    w, h = 980, 580
    parts = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">',
        "<defs><marker id=\"arrowhead\" markerWidth=\"10\" markerHeight=\"7\" refX=\"9\" refY=\"3.5\" orient=\"auto\">"
        f'<polygon points="0 0, 10 3.5, 0 7" fill="{STROKE}"/></marker></defs>',
        f'<rect width="{w}" height="{h}" fill="#ffffff"/>',
        sketch_rect(20, 50, 940, 500, "#e9ecef", dashed=True),
        svg_text(40, 35, "Spring Application Advisor Demo — Enterprise lab", 24, "start", "bold"),
        svg_text(36, 72, "Developer machine — Enterprise lab", 18, "start"),
        sketch_rect(60, 120, 170, 72, "#b2f2bb"),
        svg_text(145, 160, "spring-petclinic\n(advisor-demo)", 15),
        sketch_rect(280, 110, 210, 92, "#b2f2bb"),
        svg_text(385, 160, "Application Advisor\nCLI 1.6.3", 15),
        sketch_rect(540, 100, 260, 64, "#eebefa"),
        svg_text(670, 135, "demo/mappings/\nacme-spring-commons.json", 14),
        sketch_rect(60, 240, 170, 64, "#ffffff"),
        svg_text(145, 275, "~/.m2/settings.xml", 14),
        sketch_rect(280, 230, 180, 64, "#ffd8a8"),
        svg_text(370, 265, "Artifactory :8082", 14),
        sketch_rect(500, 220, 200, 64, "#ffd8a8"),
        svg_text(600, 255, "maven-virtual-repo", 14),
        sketch_rect(280, 330, 160, 56, "#a5d8ff"),
        svg_text(360, 362, "maven-remote-repo\n→ Maven Central", 13),
        sketch_rect(480, 330, 220, 56, "#a5d8ff"),
        svg_text(590, 355, "spring-enterprise-mvn-remote\n→ packages.broadcom.com", 12),
        sketch_rect(740, 330, 160, 56, "#a5d8ff"),
        svg_text(820, 362, "maven-local-repo", 13),
        sketch_rect(740, 230, 160, 64, "#99e9f2"),
        svg_text(820, 265, "PostgreSQL", 14),
        sketch_rect(60, 430, 200, 72, "#e9ecef", dashed=True),
        svg_text(160, 472, "Git server :2222\n(optional)", 14),
        svg_text(400, 470, "Mappings loaded by CLI — no Advisor Server", 14, "start"),
        svg_arrow(230, 156, 280, 156),
        svg_arrow(490, 132, 540, 132),
        svg_arrow(145, 192, 145, 240),
        svg_arrow(230, 272, 280, 262),
        svg_arrow(460, 262, 500, 252),
        svg_arrow(600, 284, 600, 330),
        svg_arrow(420, 358, 480, 358),
        svg_arrow(700, 358, 740, 358),
        svg_arrow(820, 294, 820, 330),
        svg_arrow(820, 230, 820, 294),
        svg_arrow(145, 192, 145, 430, dashed=True),
        "</svg>",
    ]
    path.write_text("\n".join(parts), encoding="utf-8")


def main() -> None:
    ASSETS.mkdir(parents=True, exist_ok=True)
    write_excalidraw(ASSETS / "spring-advisor-demo-minimal.excalidraw", build_minimal())
    write_excalidraw(ASSETS / "spring-advisor-demo-enterprise-lab.excalidraw", build_enterprise())
    write_svg_minimal(ASSETS / "spring-advisor-demo-minimal.svg")
    write_svg_enterprise(ASSETS / "spring-advisor-demo-enterprise-lab.svg")
    print("Generated diagrams in", ASSETS)


if __name__ == "__main__":
    main()
