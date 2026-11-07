import Foundation

extension MCPServer {
  static let instructions =
    "Search the registry, describe an item to read its usage snippet and source, plan an install to see the dependency closure and target writes, then install. Installs copy Swift source into the destination and write a receipt; they never edit project files. Recipes are native guidance and install nothing. A preset code from the website's /create page or the Showcase's tuning panel describes a RegistryTheme; apply_preset writes it as RegistryTheme+App.swift next to the installed items."
  static let tools: OrderedJSON = {
    // Protocol declarations carried over unchanged from the former Python server; MCPTests pins the wire shape.
    try! OrderedJSON.read(
      Data(
        #"""
        [
          {
            "name": "search_items",
            "title": "Search registry items",
            "description": "Find components, blocks, and recipes by name, alias, tag, or description. Every query term must match.",
            "inputSchema": {
              "type": "object",
              "properties": {
                "query": {
                  "type": "string",
                  "description": "Space-separated terms; empty lists everything"
                },
                "kind": {
                  "type": "string",
                  "enum": [
                    "component",
                    "block",
                    "flow",
                    "recipe"
                  ]
                },
                "platform": {
                  "type": "string",
                  "description": "Platform name such as iOS"
                },
                "targetVersion": {
                  "type": "string",
                  "description": "Deployment target such as 26.0"
                }
              }
            },
            "annotations": {
              "readOnlyHint": true,
              "idempotentHint": true
            }
          },
          {
            "name": "describe_item",
            "title": "Describe an item",
            "description": "Metadata, the call-site usage snippet, native guidance for recipes, the dependency closure, package requirements, and the canonical Swift source.",
            "inputSchema": {
              "type": "object",
              "properties": {
                "name": {
                  "type": "string"
                }
              },
              "required": [
                "name"
              ]
            },
            "annotations": {
              "readOnlyHint": true,
              "idempotentHint": true
            }
          },
          {
            "name": "plan_install",
            "title": "Plan an install",
            "description": "Resolve like a real install and report every target write with its status (new, up-to-date, modified-would-require-force, would-merge) plus package requirements. Writes nothing.",
            "inputSchema": {
              "type": "object",
              "properties": {
                "name": {
                  "type": "string"
                },
                "destination": {
                  "type": "string",
                  "description": "Folder inside the consuming target's sources, absolute or relative to the client's working directory"
                }
              },
              "required": [
                "name",
                "destination"
              ]
            },
            "annotations": {
              "readOnlyHint": true,
              "idempotentHint": true
            }
          },
          {
            "name": "diff_item",
            "title": "Diff owned source",
            "description": "Unified diff of each receipt-backed owned file against the canonical registry source. Requires an existing installation receipt.",
            "inputSchema": {
              "type": "object",
              "properties": {
                "name": {
                  "type": "string"
                },
                "destination": {
                  "type": "string",
                  "description": "Folder inside the consuming target's sources, absolute or relative to the client's working directory"
                }
              },
              "required": [
                "name",
                "destination"
              ]
            },
            "annotations": {
              "readOnlyHint": true,
              "idempotentHint": true
            }
          },
          {
            "name": "install_item",
            "title": "Install an item",
            "description": "Copy the item and its dependency closure into the destination and write the receipt. Refuses to overwrite modified owned source unless force is true. Never edits project files.",
            "inputSchema": {
              "type": "object",
              "properties": {
                "name": {
                  "type": "string"
                },
                "destination": {
                  "type": "string",
                  "description": "Folder inside the consuming target's sources, absolute or relative to the client's working directory"
                },
                "force": {
                  "type": "boolean",
                  "default": false
                }
              },
              "required": [
                "name",
                "destination"
              ]
            },
            "annotations": {
              "readOnlyHint": false,
              "destructiveHint": true,
              "idempotentHint": true
            }
          },
          {
            "name": "describe_preset",
            "title": "Describe a preset code",
            "description": "Decode a preset code into its theme knobs, the RegistryTheme Swift it stands for, and its website URL.",
            "inputSchema": {
              "type": "object",
              "properties": {
                "code": {
                  "type": "string",
                  "description": "A preset code such as a13GkaOXWwIF, with or without a --preset prefix"
                }
              },
              "required": [
                "code"
              ]
            },
            "annotations": {
              "readOnlyHint": true,
              "idempotentHint": true
            }
          },
          {
            "name": "apply_preset",
            "title": "Apply a preset code",
            "description": "Write RegistryTheme+App.swift for the code into the destination, declaring RegistryTheme.app to apply once at the scene root. Refuses to replace a theme file edited by hand unless force is true.",
            "inputSchema": {
              "type": "object",
              "properties": {
                "code": {
                  "type": "string"
                },
                "destination": {
                  "type": "string",
                  "description": "Folder inside the consuming target's sources, absolute or relative to the client's working directory"
                },
                "force": {
                  "type": "boolean",
                  "default": false
                }
              },
              "required": [
                "code",
                "destination"
              ]
            },
            "annotations": {
              "readOnlyHint": false,
              "destructiveHint": true,
              "idempotentHint": true
            }
          },
          {
            "name": "list_design_notes",
            "title": "List design notes",
            "description": "Read the notes a person left in the app's Tune panel (design-notes.json): each names the item and its chain, the screen, the tokens the item reads, its moved knobs, its frame, the preset code that was up, and whether it is resolved. Give the file, or the simulator udid and the app's bundleId to find it in the app container.",
            "inputSchema": {
              "type": "object",
              "properties": {
                "file": {
                  "type": "string",
                  "description": "Path of design-notes.json; absolute, ~-relative, or relative to the client's working directory"
                },
                "udid": {
                  "type": "string",
                  "description": "Simulator UDID, with bundleId, when file is not given"
                },
                "bundleId": {
                  "type": "string",
                  "description": "The app's bundle identifier, with udid"
                },
                "includeResolved": {
                  "type": "boolean",
                  "default": false
                }
              }
            },
            "annotations": {
              "readOnlyHint": true,
              "idempotentHint": true
            }
          },
          {
            "name": "get_design_context",
            "title": "Get the design context",
            "description": "What the person sees on the device while the Tune panel is up (design-context.json): the named screen, every registry item on it with its frame in window points, the tokens it reads and its moved knobs, the selection, the preset code, the environment switches, and the screenshots saved under notes/ (absolute paths; read one to see the screen). Locate the file as list_design_notes does.",
            "inputSchema": {
              "type": "object",
              "properties": {
                "file": {
                  "type": "string",
                  "description": "Path of design-context.json"
                },
                "udid": {
                  "type": "string"
                },
                "bundleId": {
                  "type": "string"
                }
              }
            },
            "annotations": {
              "readOnlyHint": true,
              "idempotentHint": true
            }
          },
          {
            "name": "set_tuning",
            "title": "Set the theme on the device",
            "description": "Write a theme into the app's registry-tokens.json; the Tune panel and every registry item follow at once, no rebuild. Give a preset code, or a tuning object (any subset of the describe_preset keys) merged over the theme the device has now. The previous theme is recorded so the person can undo. Locate the file as list_design_notes does.",
            "inputSchema": {
              "type": "object",
              "properties": {
                "code": {
                  "type": "string",
                  "description": "A preset code, with or without --preset"
                },
                "tuning": {
                  "type": "object",
                  "description": "Knobs to change, by describe_preset key, such as {\"accent\": \"green\", \"cardRadius\": 20}"
                },
                "file": {
                  "type": "string"
                },
                "udid": {
                  "type": "string"
                },
                "bundleId": {
                  "type": "string"
                }
              }
            },
            "annotations": {
              "readOnlyHint": false,
              "destructiveHint": false,
              "idempotentHint": true
            }
          },
          {
            "name": "set_knobs",
            "title": "Set an item's knobs on the device",
            "description": "Write per-item knob values into the app's design-knobs.json; the item follows at once. values maps a knob name to a number, or null to return it to its shipped default. The previous values are recorded so the person can undo. Locate the file as list_design_notes does.",
            "inputSchema": {
              "type": "object",
              "properties": {
                "item": {
                  "type": "string"
                },
                "values": {
                  "type": "object"
                },
                "file": {
                  "type": "string"
                },
                "udid": {
                  "type": "string"
                },
                "bundleId": {
                  "type": "string"
                }
              },
              "required": [
                "item",
                "values"
              ]
            },
            "annotations": {
              "readOnlyHint": false,
              "destructiveHint": false,
              "idempotentHint": true
            }
          },
          {
            "name": "resolve_design_note",
            "title": "Resolve a design note",
            "description": "Mark a note resolved in design-notes.json once its work is done; the Tune panel then drops it from its list. Locate the file as list_design_notes does.",
            "inputSchema": {
              "type": "object",
              "properties": {
                "id": {
                  "type": "string",
                  "description": "The note's id, from list_design_notes"
                },
                "file": {
                  "type": "string"
                },
                "udid": {
                  "type": "string"
                },
                "bundleId": {
                  "type": "string"
                }
              },
              "required": [
                "id"
              ]
            },
            "annotations": {
              "readOnlyHint": false,
              "destructiveHint": false,
              "idempotentHint": true
            }
          }
        ]
        """#.utf8))
  }()
}
