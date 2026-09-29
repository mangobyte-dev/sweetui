import Testing

@testable import SweetUIKit

@Test func jsonLayout() {
  #expect(
    JSON.object(["b": [], "a": "value"]).rendered() == "{\n  \"a\": \"value\",\n  \"b\": []\n}")
}
