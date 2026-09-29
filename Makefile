ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

.PHONY: format format-check

format:
	swift format format --in-place --recursive "$(ROOT)/Sources/SweetUIKit" "$(ROOT)/Sources/SweetUICLI" "$(ROOT)/Tests/SweetUIKitTests"

format-check:
	swift format lint --strict --recursive "$(ROOT)/Sources/SweetUIKit" "$(ROOT)/Sources/SweetUICLI" "$(ROOT)/Tests/SweetUIKitTests"
