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
          }
        ]
        """#.utf8))
  }()
}
