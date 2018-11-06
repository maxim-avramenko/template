ENV_FILE = .env

all: check

check:
	if [ ! -f $(ENV_FILE) ]; then \
		echo Please, run ./configure [ OPTIONS ] first; \
	fi

install: check



clean:
	echo "remove trash"