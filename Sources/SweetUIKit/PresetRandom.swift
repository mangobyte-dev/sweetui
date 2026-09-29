import Dependencies
import Foundation

/// CPython's integer-seeded MT19937 and randrange rejection sampling.
/// Seeded output is part of preset command parity, so SystemRandomNumberGenerator
/// cannot replace this algorithm.
struct PythonRandom {
  var state = [UInt32](repeating: 0, count: 624)
  var index = 624
  init(keys: [UInt32]) {
    state[0] = 19_650_218
    for i in 1..<624 {
      state[i] = 1_812_433_253 &* (state[i - 1] ^ (state[i - 1] >> 30)) &+ UInt32(i)
    }
    var i = 1
    var j = 0
    for _ in 0..<max(624, keys.count) {
      state[i] =
        (state[i] ^ ((state[i - 1] ^ (state[i - 1] >> 30)) &* 1_664_525)) &+ keys[j] &+ UInt32(j)
      i += 1
      j += 1
      if i >= 624 {
        state[0] = state[623]
        i = 1
      }
      if j >= keys.count { j = 0 }
    }
    for _ in 0..<623 {
      state[i] = (state[i] ^ ((state[i - 1] ^ (state[i - 1] >> 30)) &* 1_566_083_941)) &- UInt32(i)
      i += 1
      if i >= 624 {
        state[0] = state[623]
        i = 1
      }
    }
    state[0] = 0x8000_0000
  }
  mutating func next() -> UInt32 {
    if index >= 624 {
      for i in 0..<624 {
        let y = (state[i] & 0x8000_0000) | (state[(i + 1) % 624] & 0x7fff_ffff)
        state[i] = state[(i + 397) % 624] ^ (y >> 1) ^ (y & 1 == 1 ? 0x9908_b0df : 0)
      }
      index = 0
    }
    var y = state[index]
    index += 1
    y ^= y >> 11
    y ^= (y << 7) & 0x9d2c_5680
    y ^= (y << 15) & 0xefc6_0000
    y ^= y >> 18
    return y
  }
  mutating func bits(_ width: Int) -> Int { Int(next() >> (32 - width)) }
  mutating func below(_ count: Int) -> Int {
    let width = Int.bitWidth - count.leadingZeroBitCount
    var value = bits(width)
    while value >= count { value = bits(width) }
    return value
  }
  mutating func random() -> Double {
    (Double(next() >> 5) * 67_108_864 + Double(next() >> 6)) / 9_007_199_254_740_992
  }
}

extension Preset {
  public static func random(seed: Int64? = nil) throws -> String {
    try random(seedText: seed.map(String.init))
  }
  public static func random(seedText: String?) throws -> String {
    @Dependency(\.uuid) var uuid
    let digits = seedText?.trimmingCharacters(in: .whitespacesAndNewlines)
    var keys: [UInt32] = [0]
    if let digits {
      guard matches(digits, "^[+-]?[0-9](?:_?[0-9])*$") else {
        throw RegistryError("invalid integer seed: \(digits)")
      }
      for digit in digits where digit != "+" && digit != "-" && digit != "_" {
        var carry = UInt64(digit.wholeNumberValue!)
        for i in keys.indices {
          let value = UInt64(keys[i]) * 10 + carry
          keys[i] = UInt32(truncatingIfNeeded: value)
          carry = value >> 32
        }
        if carry > 0 { keys.append(UInt32(carry)) }
      }
    } else {
      let entropy = uuid().uuidString.replacingOccurrences(of: "-", with: "")
      keys = stride(from: 0, to: 32, by: 8).map { offset in
        UInt32(entropy.dropFirst(offset).prefix(8), radix: 16)!
      }
    }
    var random = PythonRandom(keys: keys)
    var tuning: JSON = [
      "accent": .string(accents[random.below(accents.count)]),
      "darkLabelOnAccent": .bool(random.below(2) == 1),
    ]
    for field in fields {
      let scale = pow(10, Double(field.decimals))
      tuning[field.key] = .number(
        ((field.minimum + Double(random.below(field.count)) * field.step) * scale).rounded(
          .toNearestOrEven) / scale)
    }
    if tuning["accent"] == "custom" {
      tuning["customAccent"] = .string(hex(random.bits(24)))
      tuning["customAccentDark"] = random.random() < 0.5 ? .string(hex(random.bits(24))) : .null
    }
    return try encode(tuning)
  }
}
