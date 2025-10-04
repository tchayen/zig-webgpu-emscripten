Note 2025-10-04: tried to update to zig 0.15. Dependencies were not ready yet.

```
zig build
```

To compile everything.

For native app run:

```
zig build run
```

For emscripten:

```
python3 -m http.server
```

Use python to serve files and then visit `localhost:8000/emscripten-output.html` in your browser.
