cmake_minimum_required(VERSION 3.9...3.18)

project(PiGpio VERSION 1.0
               DESCRIPTION "Controlling the Pi4's GPIOs on low level"
               LANGUAGES C)

add_executable(hello src/hello.c)