# Formula template for the mangobyte-dev/homebrew-tap repository, as Formula/sweetui.rb.
# The release workflow uploads sweetui-macos-universal.tar.gz and its .sha256 to the
# GitHub release of the tag; copy that checksum into sha256 below, and tag the tap
# sweetui-<version> so the tool's update notice can see the release.
# The first sweetui release also adds formula_renames.json {"swiftui-registry": "sweetui"} at the
# tap root, removes Formula/swiftui-registry.rb, and tags swiftui-registry-<version> too: released
# 0.4.0 binaries look only for that tag prefix.
class Sweetui < Formula
  desc "Copy source-owned SwiftUI registry items into your app and keep them updatable"
  homepage "https://github.com/mangobyte-dev/sweetui"
  url "https://github.com/mangobyte-dev/sweetui/releases/download/0.6.0/sweetui-macos-universal.tar.gz"
  version "0.6.0"
  sha256 "0000000000000000000000000000000000000000000000000000000000000000"
  license "MIT"

  depends_on :macos

  def install
    bin.install "sweetui"
  end

  test do
    assert_match "0.6.0", shell_output("#{bin}/sweetui --version")
  end
end
