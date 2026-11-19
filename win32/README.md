# dvtm for Windows (native MSVC)

Native port of dvtm: no Cygwin, MSYS or WSL. Each window runs in its own
ConPTY pseudoconsole; drawing uses PDCursesMod's wincon backend (downloaded
pinned by CMake).

## Build and test

```bat
win32\build.bat
powershell -ExecutionPolicy Bypass -File win32\tests\run-tests.ps1
```

Requires Windows 10 1809+ (ConPTY), Visual Studio with C++, CMake 3.20+ and
git (for FetchContent). Offline: `win32\build.bat -DPDCURSES_DIR=C:\path\to\PDCursesMod`.

## Usage (same as upstream)

```bat
dvtm                    :: windows run %SHELL% or %COMSPEC%
dvtm powershell.exe
```

Ctrl+G is the modifier: `Ctrl+G c` new window, `Ctrl+G j/k` focus,
`Ctrl+G q q` quit. Pair it with the abduco port for detachable sessions.

## Windows differences

- Children get `TERM=xterm-256color`: they talk to conhost (behind ConPTY),
  not to dvtm's emulator.
- `-s`/`-c` (status/command FIFOs) are not supported yet (`mkfifo` -> ENOSYS).
- New windows start in dvtm's directory (no `/proc/<pid>/cwd`).
- Characters outside the BMP take two cells (`wchar_t` is UTF-16).

## Layout

```
win32/compat/   POSIX-on-Win32 layer (virtual fds, select over
                WaitForMultipleObjects, emulated signals, ConPTY,
                AF_UNIX, termios on the console). Upstream code never
                sees <windows.h>: compat.h is force-included (/FI).
win32/tests/    ptyrun.c (scripted ConPTY terminal) + run-tests.ps1
```

All source changes are under `#ifdef _WIN32` and tagged `WIN32:`; see
`git diff 7bcf43f..port/windows -- . ':!win32'`.

Debugging a detached server: `set COMPAT_TRACE=C:\path\trace.log`.

The port and its write-up come from the N5-multiplexers kata of
[LowLevel-Katas](https://github.com/5hif7y/LowLevel-Katas).
