.PHONY: release

release:
	zip -x "release/" -x "release/.*" -9 -r release/pong.love *
