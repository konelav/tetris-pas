default: tetris

SRC=./src
SOURCES=$(wildcard $(SRC)/*.pas)


tetris: $(SOURCES)
	fpc $(SRC)/tetris.pas
	cp $(SRC)/tetris .

clean:
	rm tetris $(SRC)/tetris $(SRC)/*.o $(SRC)/*.ppu
