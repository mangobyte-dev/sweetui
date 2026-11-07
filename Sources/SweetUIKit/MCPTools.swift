import Foundation

extension MCPServer {
  static let instructions =
    "Search the registry, describe an item to read its usage snippet and source, plan an install to see the dependency closure and target writes, then install. Installs copy Swift source into the destination and write a receipt; they never edit project files. Recipes are native guidance and install nothing. A preset code from the website's /create page or Tune's Copy code describes a RegistryTheme; apply_preset writes it as RegistryTheme+App.swift next to the installed items."
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
            "description": "Decode a preset code into its theme tokens, the RegistryTheme Swift it stands for, and its website URL.",
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
            "description": "Read the notes the person left in Tune (design-notes.json), oldest first: each names its subject (the item and its chain, or the screen), the tokens the item reads, its moved knobs, its frame, the design's code (empty under Source), its screenshot, inReplyTo when it follows a note or a proposal, and your answer once you gave one. Also every proposal you made, with its state: offered, trying, kept, or discarded, which is what the person decided. Listing stamps each returned note read, so the person sees that you read it. Give the file, or the simulator udid and the app's bundleId to find it in the app container.",
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
                "includeAnswered": {
                  "type": "boolean",
                  "default": false,
                  "description": "Also list the notes you already answered"
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
            "name": "answer_design_note",
            "title": "Answer a design note",
            "description": "Answer a note in Tune: the reply the person reads under the note and the files you changed for it, written to design-agent.json beside the notes. A later answer to the same note replaces the earlier one. Refuses an id design-notes.json does not hold. Locate the file as list_design_notes does.",
            "inputSchema": {
              "type": "object",
              "properties": {
                "id": {
                  "type": "string",
                  "description": "The note's id, from list_design_notes"
                },
                "reply": {
                  "type": "string",
                  "description": "What you did, or why not, in a sentence or two"
                },
                "changedFiles": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  },
                  "description": "Paths you changed for this note"
                },
                "file": {
                  "type": "string",
                  "description": "Path of design-notes.json"
                },
                "udid": {
                  "type": "string",
                  "description": "Simulator UDID, with bundleId, when file is not given"
                },
                "bundleId": {
                  "type": "string",
                  "description": "The app's bundle identifier, with udid"
                }
              },
              "required": [
                "id",
                "reply"
              ]
            },
            "annotations": {
              "readOnlyHint": false,
              "destructiveHint": false,
              "idempotentHint": true
            }
          },
          {
            "name": "propose_design",
            "title": "Propose a design",
            "description": "Offer the person a design in Tune, appended to design-agent.json: a name, a reason, the note it answers, and either a full code or tokens as a delta of describe_preset keys (only what changes), plus knobs per item, with null returning a knob to its default. With apply true Tune tries it on the device at once, merged over the current design version, card open or closed; with apply false it waits in Notes for the person to try. The person keeps or discards it, and list_design_notes reports which. Validates the code, the token keys and values (a number on its preset grid, as describe_preset decodes it), and the knobs before writing, and refuses code and tokens when the host does not tune the theme (tunesTheme false in design-context.json). Never writes registry-tokens.json or design-knobs.json.",
            "inputSchema": {
              "type": "object",
              "properties": {
                "name": {
                  "type": "string",
                  "description": "A short name the person reads in the Trying strip, such as Warm"
                },
                "reason": {
                  "type": "string",
                  "description": "Why this design, in a sentence"
                },
                "note": {
                  "type": "string",
                  "description": "The id of the note it answers, from list_design_notes"
                },
                "code": {
                  "type": "string",
                  "description": "A full preset code, with or without --preset; give this or tokens"
                },
                "tokens": {
                  "type": "object",
                  "description": "Only the tokens that change, by describe_preset key, such as {\"accent\": \"teal\", \"cardRadius\": 20}"
                },
                "knobs": {
                  "type": "object",
                  "description": "Knob values per item, such as {\"button\": {\"height\": 44, \"radius\": null}}; null is the knob's default"
                },
                "apply": {
                  "type": "boolean",
                  "default": true,
                  "description": "Try it on the device at once"
                },
                "file": {
                  "type": "string",
                  "description": "Path of design-agent.json"
                },
                "udid": {
                  "type": "string",
                  "description": "Simulator UDID, with bundleId, when file is not given"
                },
                "bundleId": {
                  "type": "string",
                  "description": "The app's bundle identifier, with udid"
                }
              },
              "required": [
                "name"
              ]
            },
            "annotations": {
              "readOnlyHint": false,
              "destructiveHint": false,
              "idempotentHint": false
            }
          },
          {
            "name": "get_design_context",
            "title": "Get the design context",
            "description": "What the person sees on the device while Tune is on, card open or closed (design-context.json): the named screen, every registry item on it with its frame in window points, the tokens it reads and its moved knobs, the selection, the design's code (empty under Source, when the app shows its own theme), the code the last screenshot shows, the proposal trying now, whether the host tunes the theme (tunesTheme), Preview's overrides, and the screenshots saved under notes/ (absolute paths; read one to see the screen). Locate the file as list_design_notes does.",
            "inputSchema": {
              "type": "object",
              "properties": {
                "file": {
                  "type": "string",
                  "description": "Path of design-context.json"
                },
                "udid": {
                  "type": "string",
                  "description": "Simulator UDID, with bundleId, when file is not given"
                },
                "bundleId": {
                  "type": "string",
                  "description": "The app's bundle identifier, with udid"
                }
              }
            },
            "annotations": {
              "readOnlyHint": true,
              "idempotentHint": true
            }
          },
          {
            "name": "read_handoff",
            "title": "Read the hand-off from the device",
            "description": "Read the hand-off the person sent from Tune's Versions (design-handoff.json): its id, the design's code (empty under Source) and its Swift, every moved knob, the changes from Default, the open notes with their screenshots, and the previous hand-off's id. Reading stamps this hand-off read, so the person sees it. Write the theme and the knob defaults into source, answer the open notes, build and relaunch the app, then call answer_handoff. Locate the file as list_design_notes does.",
            "inputSchema": {
              "type": "object",
              "properties": {
                "file": {
                  "type": "string",
                  "description": "Path of design-handoff.json"
                },
                "udid": {
                  "type": "string",
                  "description": "Simulator UDID, with bundleId, when file is not given"
                },
                "bundleId": {
                  "type": "string",
                  "description": "The app's bundle identifier, with udid"
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
            "name": "answer_handoff",
            "title": "Answer a hand-off",
            "description": "Answer a hand-off in Tune, written to design-agent.json: a reply and the files you changed. Build and relaunch the app with those files first: the app shows only the source it was built with. With changedFiles the person sees Shipped and, while the device still shows the design handed off, Tune clears its token and knob overrides, so the app shows your source; without them the reply shows alone. Accepts the current hand-off and the one before it, and says when a newer one waits; refuses an older id. Locate the file as list_design_notes does.",
            "inputSchema": {
              "type": "object",
              "properties": {
                "id": {
                  "type": "string",
                  "description": "The hand-off's id, from read_handoff"
                },
                "reply": {
                  "type": "string",
                  "description": "What you put into source, in a sentence or two"
                },
                "changedFiles": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  },
                  "description": "Paths you changed; Tune then shows Shipped"
                },
                "file": {
                  "type": "string",
                  "description": "Path of design-handoff.json"
                },
                "udid": {
                  "type": "string",
                  "description": "Simulator UDID, with bundleId, when file is not given"
                },
                "bundleId": {
                  "type": "string",
                  "description": "The app's bundle identifier, with udid"
                }
              },
              "required": [
                "id",
                "reply"
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
