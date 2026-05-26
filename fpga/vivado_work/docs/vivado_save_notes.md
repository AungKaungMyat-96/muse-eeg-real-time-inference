# Vivado Save Notes

## Safe Save Procedure

1. Save project: `File -> Save Project`.
2. Close active simulation safely:
   - Stop run if active.
   - Close simulation window/session cleanly.
3. Regenerate compile order in Tcl console:

```tcl
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
```

## Recommended Archive/Backup Procedure

1. Save project first.
2. Create a timestamped backup folder.
3. Copy project and source collateral.
4. Optionally create compressed archive (`.zip`/`.7z`) for transport.

## Recommended Backup Files/Folders

- `.xpr`
- `muse_cnn_sources/`
- `constraints/`
- `scripts/`
- `docs/`
