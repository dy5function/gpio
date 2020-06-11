# Controlling the Pi4's GPIOs on low-level

As stated in the `README.md`, the goal of this project is to make LEDs go bling without using external libraries. Starting from complete zero, I will first need to find out what compiler I need to use for getting anything to work on the *Pi4*. Can't be that hard to find out, right?

---

**DISCLAIMER** | Anything that is described here may not be the best, most elegant or sophisticated way to do whatever is done and may even be completely inadequate. I do not intend to only describe a working solution in this devlog but want to also document things I tried that did not work in the end. Therefore, this document is probably not well suited for someone who tries to find a quick solution to a problem. It may however be instructive for someone trying to learn about the Pi, hardware and software like I do myself. Learning and developing is not only about success stories but 95% about failures.

---
