.PHONY: love

love: clean
	zip -x "release/" -x "release/.*" -9 -r release/pong.love *

clean:
	rm release/*
