# Building the Toolchain

A simple manual on how to build toolchain for the RPi 4 using Crosstool-ng:

## Installing Crosstool-ng

Install the packages needed:

```
sudo apt install build-essential git autoconf bison flex texinfo help2man gawk libtool-bin libncurses5-dev unzip
```

Let’s download the sources of Crosstool-ng, through its git source repository, and switch to a tested commit:

```
git clone https://github.com/crosstool-ng/crosstool-ng
cd crosstool-ng/
git checkout crosstool-ng-1.26.0
```

We can install Crosstool-ng locally in its download directory:

```
./bootstrap
./configure --enable-local
make
sudo make install
```

## Building the Toolchain

By default, Crosstool-ng comes with a few ready-to-use configurations. You can see the full list by typing:

```
./ct-ng list-samples
```

Currently, there are no configurations for RPi 4. To avoid creating one from scratch, we can use an existing configuration of RPi 3 and modify it to match RPi 4.

Select **aarch64-rpi3-linux-musl** as a base-line configuration by typing:

```
./ct-ng aarch64-rpi3-linux-musl
```

To customize the build for the RPi 4:

```
./ct-ng menuconfig
```

Make 3 changes:

1) Allow extending the toolchain after it is created (by default, it is created as read-only):

Paths and misc options > Render the toolchain read-only: Dismark

2) Change the ARM Cortex core:

Target options -> Emit assembly for CPU: Change "cortex-a53" to "cortex-a72"

3) Chanbe the tuple’s vendor string:

Toolchain options -> Tuple’s vendor string: Change "rpi3" to "rpi4"

Additionaly, you can:

In Path and misc options:
-If not set yet, enable Try features marked as EXPERIMENTAL

In Target options:
- Set Tuple's alias (TARGET_ALIAS) to arm-linux. This way, we will be able to use the compiler as arm-linux-gcc instead of arm-rpi4-linux-musl-gcc, which is much longer to type.

In Operating System:
- Set Version of linux to the closest, but older version to 6.6. It’s important that the kernel headers used in the toolchain are not more recent than the kernel that will run on the board (v6.6).

In C-library:
- If not set yet, set C library to musl (LIBC_MUSL)
- Keep the default version that is proposed

In C compiler:
- Set Version of gcc to 13.2.0.
- Make sure that C++ (CC_LANG_CXX) is enabled

In Debug facilities:
- Remove all options here. Some debugging tools can be provided in the toolchain, but they can also be built by filesystem building tools.

To build the toolchain:

```
./ct-ng build
```

The toolchain will be installed by default in \$HOME/x-tools/. That’s something you could have changed in Crosstool-ng’s configuration.

You can now test your toolchain by adding \$HOME/x-tools/arm-rpi4-linux-musl/bin/to your PATH environment variable (via **export** command or in the .bashrc file).

```
PATH=~/x-tools/aarch64-rpi4-linux-musl/bin:$PATH
```

You can copy it to /opt if you want:

```
PATH=/opt/aarch64-rpi4-linux-musl/bin:$PATH
```

To test the toolchain:

```
arm-linux-gcc -v
```

You can use the **file** command on your binary to make sure it has correctly been compiled for the ARM architecture.
