CC = aarch64-linux-gnu-gcc
CFLAGS = -Wall
BUILD_DIR = build
SOURCE_DIR = src

hello: $(SOURCE_DIR)/hello.c
	$(CC) $(CFLAGS) -o $(BUILD_DIR)/$@ $^

clean:
	rm -rf $(BUILD_DIR)/*
