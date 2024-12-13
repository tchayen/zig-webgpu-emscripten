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
