import Foundation

/// Untyped metadata stays inspectable until the structural validator accepts it.
public enum JSON: Equatable, Sendable, Codable, ExpressibleByStringLiteral,
  ExpressibleByIntegerLiteral, ExpressibleByFloatLiteral, ExpressibleByBooleanLiteral,
  ExpressibleByArrayLiteral, ExpressibleByDictionaryLiteral, ExpressibleByNilLiteral
{
  case object([String: JSON])
  case array([JSON])
  case string(String)
  case number(Double)
  case bool(Bool)
  case null
  public init(stringLiteral value: String) { self = .string(value) }
  public init(integerLiteral value: Int) { self = .number(Double(value)) }
  public init(floatLiteral value: Double) { self = .number(value) }
  public init(booleanLiteral value: Bool) { self = .bool(value) }
  public init(arrayLiteral elements: JSON...) { self = .array(elements) }
  public init(dictionaryLiteral elements: (String, JSON)...) {
    self = .object(Dictionary(uniqueKeysWithValues: elements))
  }
  public init(nilLiteral: ()) { self = .null }
  public init(from decoder: any Decoder) throws {
    let c = try decoder.singleValueContainer()
    if c.decodeNil() {
      self = .null
    } else if let v = try? c.decode(Bool.self) {
      self = .bool(v)
    } else if let v = try? c.decode(String.self) {
      self = .string(v)
    } else if let v = try? c.decode(Double.self) {
      self = .number(v)
    } else if let v = try? c.decode([JSON].self) {
      self = .array(v)
    } else {
      self = .object(try c.decode([String: JSON].self))
    }
  }
  public func encode(to encoder: any Encoder) throws {
    var c = encoder.singleValueContainer()
    switch self {
    case .null: try c.encodeNil()
    case .bool(let v): try c.encode(v)
    case .number(let v): try c.encode(v)
    case .string(let v): try c.encode(v)
    case .array(let v): try c.encode(v)
    case .object(let v): try c.encode(v)
    }
  }
  public var object: [String: JSON]? { if case .object(let v) = self { v } else { nil } }
  public var array: [JSON]? { if case .array(let v) = self { v } else { nil } }
  public var string: String? { if case .string(let v) = self { v } else { nil } }
  public var number: Double? { if case .number(let v) = self { v } else { nil } }
  public var text: String { string ?? "" }
  public var strings: [String] { array?.compactMap(\.string) ?? [] }
  public subscript(_ key: String) -> JSON {
    get { object?[key] ?? .null }
    set {
      var v = object ?? [:]
      v[key] = newValue
      self = .object(v)
    }
  }
  public static func read(_ data: Data) throws -> JSON {
    try JSONDecoder().decode(Self.self, from: data)
  }
  /// Python's indent=2 layout, sorted keys and ensure_ascii=True.
  public func rendered(indent: Int = 2, ascii: Bool = true, level: Int = 0, keys: [String]? = nil)
    -> String
  {
    let pad = String(repeating: " ", count: indent * level)
    let child = pad + String(repeating: " ", count: indent)
    switch self {
    case .null: return "null"
    case .bool(let b): return b ? "true" : "false"
    case .number(let n):
      return n.rounded() == n && abs(n) < 1e16 ? String(format: "%.0f", n) : String(n)
    case .string(let s):
      var out = "\""
      for u in s.unicodeScalars {
        switch u.value {
        case 34: out += "\\\""
        case 92: out += "\\\\"
        case 8: out += "\\b"
        case 9: out += "\\t"
        case 10: out += "\\n"
        case 12: out += "\\f"
        case 13: out += "\\r"
        case 0..<32: out += String(format: "\\u%04x", u.value)
        default:
          if ascii && u.value > 127 {
            for unit in String(u).utf16 { out += String(format: "\\u%04x", unit) }
          } else {
            out += String(u)
          }
        }
      }
      return out + "\""
    case .array(let a):
      if a.isEmpty { return "[]" }
      return "[\n"
        + a.map { child + $0.rendered(indent: indent, ascii: ascii, level: level + 1) }.joined(
          separator: ",\n") + "\n" + pad + "]"
    case .object(let o):
      if o.isEmpty { return "{}" }
      return "{\n"
        + (keys ?? o.keys.sorted()).map {
          child + JSON.string($0).rendered(ascii: ascii) + ": "
            + o[$0, default: .null].rendered(indent: indent, ascii: ascii, level: level + 1)
        }.joined(separator: ",\n") + "\n" + pad + "}"
    }
  }
}

public struct RegistryError: Error, CustomStringConvertible, Sendable {
  public let description: String
  public init(_ message: String) { description = message }
}

func matches(_ value: String, _ pattern: String) -> Bool {
  guard let regex = try? NSRegularExpression(pattern: pattern) else { return false }
  let range = NSRange(value.startIndex..., in: value)
  return regex.firstMatch(in: value, range: range)?.range == range
}
