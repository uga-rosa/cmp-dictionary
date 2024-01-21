.PHONY: test vusted format

test: vusted

vusted:
	vusted lua/

format:
	stylua lua/
