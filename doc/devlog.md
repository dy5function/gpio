# Controlling the Pi4's GPIOs on low-level

As stated in the `README.md`, the goal of this project is to make LEDs go bling without using external libraries. Starting from complete zero, I will first need to find out what compiler I need to use for getting anything to work on the *Pi4*. Can't be that hard to find out, right?

---

**DISCLAIMER** | Anything that is described here may not be the best, most elegant or sophisticated way to do whatever is done and may even be completely inadequate. I do not intend to only describe a working solution in this devlog but want to also document things I tried that did not work in the end. Therefore, this document is probably not well suited for someone who tries to find a quick solution to a problem. It may however be instructive for someone trying to learn about the Pi, hardware and software like I do myself. Learning and developing is not only about success stories but 95% about failures.

---

## Cross-compiling for the Pi4 - An unexpected journey

I am certainly not the first one to compile for the Pi... "Ok Google, what cross-compiler do I need to compile for the Raspberry Pi?" - "Here, check out [this helpful thread on StackExchange](https://raspberrypi.stackexchange.com/questions/64273/installing-raspberry-pi-cross-compiler)" - "Thanks Google, this was easy"... On the *StackExchange* thread, they point to the [RaspberryPi GitHub](https://github.com/raspberrypi/tools) that contains the prebuilt build toolchain for the Pi, how neat! Now. I simply clone this to my development machine and include the binaries in my `PATH` for convinient access:

---

**Note** | When I show bash commands, I will include a preamble before each command to distinguish between my development machine and the Pi.

---

```bash
dev@dev-machine:~/pi$ git clone https://github.com/raspberrypi/tools
Cloning into 'tools'...
remote: Enumerating objects: 14, done.
remote: Counting objects: 100% (14/14), done.
remote: Compressing objects: 100% (10/10), done.
remote: Total 25388 (delta 7), reused 9 (delta 4), pack-reused 25374
Receiving objects: 100% (25388/25388), 610.88 MiB | 11.96 MiB/s, done.
Resolving deltas: 100% (14888/14888), done.
Updating files: 100% (19059/19059), done.

dev@dev-machine:~/pi$ echo PATH=\$PATH:~/pi/tools/arm-bcm2708/arm-linux-gnueabihf/bin >> ~/.bashrc

dev@dev-machine:~/pi$ source ~/.bashrc
```

Now I simply whip out a short little `hello-world.c` program, compile it and `scp` it to the *Pi* (which I pu on a local network at 192.168.10.11).

```bash
dev@dev-machine:~/pi/gpio$ arm-linux-gnueabihf-gcc -Wall -o build/hello src/hello.c

dev@dev-machine:~/pi/gpio$ scp build/hello ubuntu@192.168.10.11:/home/ubuntu
hello                                             100% 5896     3.8MB/s   00:00
```

On the Pi, I run my extremely sophisiticated test program:

```bash
ubuntu@pi:~$ ./hello
-bash: ./hello: No such file or directory
```

Wait, what? What is going on here? Maybe the file does not have the executable flag set for the *ubuntu* user?

```bash
ubuntu@pi:~$ ls -l ./hello
-rwxrwxr-x 1 ubuntu ubuntu 5896 Jun 10 16:50 ./hello
```

That is definitely not the problem. Let's compare the binary to a system binary. If I compiled the binary for the wrong architecture, I would have expected a different error message but this is the only thing I can think of right now:

```bash
ubuntu@pi:~$ file ./hello && file /usr/bin/file
./hello: ELF 32-bit LSB executable, ARM, EABI5 version 1 (SYSV), dynamically linked, interpreter /lib/ld-linux-armhf.so.3, for GNU/Linux 2.6.32, not stripped
/usr/bin/file: ELF 64-bit LSB shared object, ARM aarch64, version 1 (SYSV), dynamically linked, interpreter /lib/ld-linux-aarch64.so.1, BuildID[sha1]=63c34ac3727ef1615d29ce02d6b1a42a175ef83b, for GNU/Linux 3.7.0, stripped
```

Aha, so the architectures are indeed different! The *GitHub* page probably still contains the toolchain only for earlier versions of the Pi. So let's try out a different compiler:

```bash
dev@dev-machine:~$ sudo apt update
...

dev@dev-machine:~$ sudo apt install gcc-aarch64-linux-gnu
...

```

Et voilà, next attempt:

```bash
dev@dev-machine:~/pi/gpio$ aarch64-linux-gnu-gcc -Wall -o build/hello src/hello.c

dev@dev-machine:~/pi/gpio$ scp build/hello ubuntu@192.168.10.11:/home/ubuntu
hello                                             100% 9288     5.3MB/s   00:00
```

On the Pi:

```bash
ubuntu@pi:~$ ./hello
Hello, world!
```

It works! This was a little more complicated than I anticipated, but all the more satisfying in the end. Let's check the binary with `file`:

```bash
ubuntu@pi:~$ file ./hello
./hello: ELF 64-bit LSB shared object, ARM aarch64, version 1 (SYSV), dynamically linked, interpreter /lib/ld-linux-aarch64.so.1, BuildID[sha1]=2aa761107cd1d6dfaa22ceefaab15a3c0286b8d0, for GNU/Linux 3.7.0, not stripped
```

That's what I call a perfect fit, nice!
