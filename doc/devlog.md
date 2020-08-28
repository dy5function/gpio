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

## Migrating my buildsystem to cmake

After playing around a little bit with plain *make*, I realize that certain things are hard to do:

* Having a dedicated build folder with subfolders for target architectures or automatic versioning seems to be hard with plain *make*
* Linking between binaries and shared objects that are deployed to different locations compared to my build environment has given me some problems
* Overall, I do not really like the readability and maintainability of my `Makefile` to be honest...

All these issues seem to be remedied in *cmake*, so I guess I'll give it a go. Also, I have stumbled across *cmake* in multiple projects before and it seems knowing my stuff there is a nice skill to have.

I found an [interesting webpage][1] that I will use as a first resource. The claims on *cmake* in the introduction sound intriguing to me:

> It's clean, powerful, and elegant, so you can spend most of your time coding, not adding lines to an unreadable, unmaintainable Make (Or CMake 2) file. And CMake 3.11+ is supposed to be significantly faster, as well!

Sign me up for that!

Alrighty, after setting up a small test program to build with *cmake*, I whipped up a first `CMakeLists.txt` file to define my project and a first build target. After reading up a little bit, I have encountered a first question: *cmake*  requires the definition of a minimum version of *cmake* for a project in order to ensure compatibility across different build environments. While this certainly makes sense, the obvious question is: How do I figure out the actual minimum required version of *cmake* for my project? Sure, this may be a purely academic question for my very simple test case, but if I do this, I want to do this right. One simple workaround for this would be to just put my current version of *cmake* as the minimum required version. However, this would certainly impose an unnecessary restriction on people who might want to build this project in the future. After looking around for a bit, I discovered [this][2] project on GitHub which provides a *Python 3* script to automatically test a build process with different *cmake* versions. Let's give this a try.

I created a virtual *Python 3* environment for the script to localize the dependencies and started the helper to download different *cmake* versions.

```bash
dev@dev-machine:~/src/cmake_min_version$ python3 -mvenv cmake_min_version_venv

dev@dev-machine:~/src/cmake_min_version$ cmake_min_version_venv/bin/pip3 install -r requirements.txt
...

dev@dev-machine:~/src/cmake_min_version$ cmake_min_version_venv/bin/python3 cmake_downloader.py
...

dev@dev-machine:~/src/cmake_min_version$ cmake_min_version_venv/bin/python3 cmake_min_version.py ~/src/pi/gpio/
Found 88 CMake binaries from directory tools

[  0%] CMake 3.11.4 ✔ works
[ 12%] CMake 3.6.3  ✘ error
       CMakeLists.txt:1 (cmake_minimum_required)
[ 25%] CMake 3.9.4  ✔ works
[ 38%] CMake 3.8.1  ✘ error
       CMakeLists.txt:7 (project)
[ 50%] CMake 3.9.1  ✔ works
[ 71%] CMake 3.8.2  ✘ error
       CMakeLists.txt:7 (project)
[ 86%] CMake 3.9.0  ✔ works
[100%] Minimal working version: CMake 3.9.0

cmake_minimum_required(VERSION 3.9.0)
```

And that's that. Guess I'll be putting version 3.9 as minimum reuqirement for now.

[1]: https://cliutils.gitlab.io/modern-cmake/
[2]: https://github.com/nlohmann/cmake_min_version
