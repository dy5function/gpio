# Controlling the Pi4's GPIOs on low level

The goal of this project is to control the *RaspberryPi 4* GPIOs directly with system calls, without using any external libraries that hide all the fun stuff. I am aware that this is not a very useful thing to do. The motivation of this project is not the contribution of a great new piece of software to the community, but rather the selfish wish to learn more about how this works and the somewhat less selfish hope that others might find this interesting and helpful as well.

## Project structure

The project structure is quite simple:

- `/src` - This is where the juicy code is kept that makes the Pi4 go *blingbling*
- `/doc` - Here, I will try to maintain a devlog that could be insightful, painfully ridiculous or just plain boring, depending on how this project plays out.
- `Makefile` - Duh...

## Prerequisites

For this project, I am using a **Raspberry Pi 4 Model B** running *Ubuntu Server 20.04 64 bit*. You can find current *Ubuntu* releases for the *Pi* on the [Ubuntu website][1].

For compiling C-code for the *RaspberryPi 4 model B* target, a suitable cross compiler is needed (see `doc/devlog.md` for a little story on that one...). If you are using a *Linux* distribution like I do, chances are that you can use the `aarch64-linux-gnu-gcc` compiler. If you need to use a different compiler, you need to specify it in the `Makefile` before building a target.

[1]: https://ubuntu.com/download/raspberry-pi
