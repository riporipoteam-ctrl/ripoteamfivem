#!/usr/bin/env python3
"""Packs src/ into a ready-to-open Roblox place file (.rbxlx).

No external dependencies — it emits the Roblox XML place format directly:
  src/shared  -> ReplicatedStorage.Shared      (ModuleScripts)
  src/server  -> ServerScriptService.Server    (Scripts / ModuleScripts)
  src/client  -> StarterPlayer.StarterPlayerScripts.Client (LocalScripts / ModuleScripts)

The world itself is generated at runtime by the server scripts, so the place
file only needs to carry code.
"""

import os
import sys
import xml.dom.minidom

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "src")
OUT = os.path.join(ROOT, "MissilesVsCities.rbxlx")

_ref_counter = 0


def next_ref():
    global _ref_counter
    _ref_counter += 1
    return "RBX%d" % _ref_counter


def esc(text):
    return (
        text.replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
    )


def script_item(class_name, name, source):
    return (
        '<Item class="%s" referent="%s">'
        "<Properties>"
        '<string name="Name">%s</string>'
        '<ProtectedString name="Source">%s</ProtectedString>'
        "</Properties>"
        "</Item>"
    ) % (class_name, next_ref(), esc(name), esc(source))


def folder_item(name, children_xml):
    return (
        '<Item class="Folder" referent="%s">'
        "<Properties>"
        '<string name="Name">%s</string>'
        "</Properties>"
        "%s"
        "</Item>"
    ) % (next_ref(), esc(name), children_xml)


def classify(filename):
    if filename.endswith(".server.luau") or filename.endswith(".server.lua"):
        return "Script", filename.rsplit(".server.", 1)[0]
    if filename.endswith(".client.luau") or filename.endswith(".client.lua"):
        return "LocalScript", filename.rsplit(".client.", 1)[0]
    if filename.endswith(".luau") or filename.endswith(".lua"):
        return "ModuleScript", filename.rsplit(".", 1)[0]
    return None, None


def dir_items(path):
    chunks = []
    for entry in sorted(os.listdir(path)):
        full = os.path.join(path, entry)
        if os.path.isdir(full):
            chunks.append(folder_item(entry, dir_items(full)))
        else:
            class_name, name = classify(entry)
            if class_name:
                with open(full, "r", encoding="utf-8") as fh:
                    chunks.append(script_item(class_name, name, fh.read()))
    return "".join(chunks)


def service_item(class_name, children_xml, extra_props=""):
    return (
        '<Item class="%s" referent="%s">'
        "<Properties>"
        '<string name="Name">%s</string>'
        "%s"
        "</Properties>"
        "%s"
        "</Item>"
    ) % (class_name, next_ref(), class_name, extra_props, children_xml)


def main():
    shared = folder_item("Shared", dir_items(os.path.join(SRC, "shared")))
    server = folder_item("Server", dir_items(os.path.join(SRC, "server")))
    client = folder_item("Client", dir_items(os.path.join(SRC, "client")))

    starter_scripts = (
        '<Item class="StarterPlayerScripts" referent="%s">'
        "<Properties>"
        '<string name="Name">StarterPlayerScripts</string>'
        "</Properties>"
        "%s"
        "</Item>"
    ) % (next_ref(), client)

    body = "".join(
        [
            service_item("Workspace", ""),
            service_item("ReplicatedStorage", shared),
            service_item("ServerScriptService", server),
            service_item("StarterPlayer", starter_scripts),
            # MaxPlayersInternal is best-effort: newer Studio versions may ignore
            # it, in which case set max players to 5 in Game Settings instead.
            service_item(
                "Players",
                "",
                '<int name="MaxPlayersInternal">5</int>'
                '<int name="PreferredPlayersInternal">5</int>',
            ),
        ]
    )

    doc = (
        '<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" '
        'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '
        'xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" '
        'version="4">'
        "<External>null</External><External>nil</External>"
        "%s"
        "</roblox>"
    ) % body

    # Validate before writing.
    xml.dom.minidom.parseString(doc)

    with open(OUT, "w", encoding="utf-8") as fh:
        fh.write(doc)
    print("Wrote %s (%d KB)" % (OUT, os.path.getsize(OUT) // 1024))
    return 0


if __name__ == "__main__":
    sys.exit(main())
