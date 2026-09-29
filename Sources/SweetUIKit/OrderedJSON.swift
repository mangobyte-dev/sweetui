import Foundation

/// Publishing and MCP preserve Python's insertion order; receipts deliberately sort keys.
public indirect enum OrderedJSON: Sendable, ExpressibleByDictionaryLiteral,
  ExpressibleByArrayLiteral, ExpressibleByStringLiteral, ExpressibleByBooleanLiteral,
  ExpressibleByNilLiteral
{
  case object([(String, OrderedJSON)])
  case array([OrderedJSON])
  case scalar(JSON)
  case numberToken(String)

  public init(dictionaryLiteral elements: (String, OrderedJSON)...) { self = .object(elements) }
  public init(arrayLiteral elements: OrderedJSON...) { self = .array(elements) }
  public init(stringLiteral value: String) { self = .scalar(.string(value)) }
  public init(booleanLiteral value: Bool) { self = .scalar(.bool(value)) }
  public init(nilLiteral: ()) { self = .scalar(.null) }
  public init(_ value: JSON) {
    switch value {
    case .object(let fields): self = .object(fields.keys.sorted().map { ($0, Self(fields[$0]!)) })
    case .array(let values): self = .array(values.map(Self.init))
    default: self = .scalar(value)
    }
  }
  public static func string(_ value: String) -> Self { .scalar(.string(value)) }
  public static func fields(_ value: JSON, _ keys: [String]) -> Self {
    .object(keys.map { ($0, Self(value[$0])) })
  }
  public var array: [OrderedJSON]? { if case .array(let value) = self { value } else { nil } }
  public var string: String? { if case .scalar(.string(let value)) = self { value } else { nil } }
  public subscript(_ key: String) -> Self {
    get {
      guard case .object(let fields) = self else { return nil }
      return fields.first { $0.0 == key }?.1 ?? nil
    }
    set {
      guard case .object(var fields) = self else { return }
      if let index = fields.firstIndex(where: { $0.0 == key }) {
        fields[index].1 = newValue
      } else {
        fields.append((key, newValue))
      }
      self = .object(fields)
    }
  }
  public func rendered(pretty: Bool = true, ascii: Bool = true, level: Int = 0) -> String {
    let pad = pretty ? String(repeating: " ", count: level * 2) : ""
    let next = pretty ? pad + "  " : ""
    let newline = pretty ? "\n" : ""
    let separator = pretty ? ",\n" : ","
    switch self {
    case .scalar(let value): return value.rendered(ascii: ascii)
    case .numberToken(let value): return value
    case .array(let values):
      if values.isEmpty { return "[]" }
      return "[" + newline
        + values.map {
          next + $0.rendered(pretty: pretty, ascii: ascii, level: level + 1)
        }.joined(separator: separator) + newline + pad + "]"
    case .object(let fields):
      if fields.isEmpty { return "{}" }
      return "{" + newline
        + fields.map {
          next + JSON.string($0.0).rendered(ascii: ascii) + (pretty ? ": " : ":")
            + $0.1.rendered(pretty: pretty, ascii: ascii, level: level + 1)
        }.joined(separator: separator) + newline + pad + "}"
    }
  }

  /// Validate with the shared JSON decoder, then retain source order and numeric spelling.
  public static func read(_ data: Data) throws -> Self {
    _ = try JSON.read(data)
    let bytes = Array(data)
    var index = 0
    func whitespace() {
      while index < bytes.count && [9, 10, 13, 32].contains(bytes[index]) { index += 1 }
    }
    func quoted() throws -> String {
      let start = index
      index += 1
      while bytes[index] != 34 {
        if bytes[index] == 92 { index += 1 }
        index += 1
      }
      index += 1
      return try JSON.read(Data(bytes[start..<index])).text
    }
    func value() throws -> Self {
      whitespace()
      if bytes[index] == 123 {
        index += 1
        whitespace()
        var fields: [(String, Self)] = []
        while bytes[index] != 125 {
          let key = try quoted()
          whitespace()
          index += 1
          let member = try value()
          if let existing = fields.firstIndex(where: { $0.0 == key }) {
            fields[existing].1 = member
          } else {
            fields.append((key, member))
          }
          whitespace()
          if bytes[index] == 44 {
            index += 1
            whitespace()
          } else {
            break
          }
        }
        index += 1
        return .object(fields)
      }
      if bytes[index] == 91 {
        index += 1
        whitespace()
        var values: [Self] = []
        while bytes[index] != 93 {
          values.append(try value())
          whitespace()
          if bytes[index] == 44 { index += 1 } else { break }
        }
        index += 1
        return .array(values)
      }
      if bytes[index] == 34 { return .string(try quoted()) }
      let start = index
      while index < bytes.count && ![9, 10, 13, 32, 44, 93, 125].contains(bytes[index]) {
        index += 1
      }
      let token = String(decoding: bytes[start..<index], as: UTF8.self)
      switch token {
      case "true": return true
      case "false": return false
      case "null": return nil
      default: return .numberToken(token)
      }
    }
    return try value()
  }
}
