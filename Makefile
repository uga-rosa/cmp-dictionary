.PHONY: test
test: luacheck vusted

.PHONY: vusted
vusted:
	vusted lua/

.PHONY: luacheck
luacheck:
	luacheck lua/
