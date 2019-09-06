## Breaking Changes
wizparse is not 100% compatible with the original parser / interpreter.

I took this opportunity to fix some gigantic missteps in the original language.
For example, this was valid syntax:

```
If a = 1
    Note 'foo'
EndIf
```

How would you guess this executed?
The answer is that it would *always* execute the `Note 'foo'` statement,
since `a = 1` is an *assignment*, not a *comparison*, and returned the new value.
The author probably meant to write this:

```
If a == 1
    Note 'foo'
EndIf
```

An actual example of a wizard that fell prey to this was the 1.97 version of SMIM for Skyrim LE:

```
If bHalfTex = 1
    SelectSubPackage "81 Half-Sized Furniture Skyrim HD Appearance"
EndIf
```

This would always select the half-sized textures, whether the user checked the option or not.

A full list of breaking changes follows:

- Blocks *must* be closed properly now.
  Previously, they did not have to be, since the parser read files one line at a time.
  Consider this `SelectOne` statement:
  ```
  SelectOne 'Are you happy with your selection?',\
            'Finish', 'Finish executing the wizard', '',\
            'Abort', 'Discard all changes and abort', ''
      Case 'Option 1'
          Return
      Case 'Option 2'
          Cancel 'User aborted'
  ```
  It's clearly missing an `EndSelect`.
  However, because both `Cancel` and `Return` tell the interpreter to finish executing the wizard,
  it never actually reads the next line to notice the lack of an `EndSelect`.
  This is a necessary breaking change, since we now parse the entire file before interpreting.
- As mentioned above, assignments and compound assignments no longer return a value,
  meaning that they cannot be used for commands that expect a value (e.g. If statements).
- Multiple `Default` statements for a single `SelectOne` / `SelectMany` statement are explicitly disallowed.
  Previously, they were allowed, but the second one would never be executed.
- Random unicode characters in a wizard are no longer silently ignored, but instead cause an error.
  For example, one SSE wizard had several ▒ characters (MEDIUM SHADE, U+2592) at the end of a line.
- Escape sequences are only allowed in strings now. Previously, this was legal:
  ```
  \; This is a comment
  \Note \'\f\o\o'
  ```
  Now, only these escapes are legal:
  ```
  ; This is a comment
  Note '\f\o\o'
  ```
  Note, however, that we still support arbitrary escape sequences in strings.
  This means you can escape any character in a string, even completely unnecessary ones, as the example above demonstrates.
  The reason is backwards compatibility: many wizards escape way too much, so removing it would cause breakage.

  There is an exception to this. Extraneous backslashes and whitespace at the end of a line are ignored:
  ```
  ; This is legal
  Note 'foo' \\\\\\\        
  ```
  The reason is, again, backwards compatibility.
  Double and triple backslashes for line continuation occur in several wizards and are relatively easy to support.
- New keywords:
  - `DeSelectAllPlugins`
  - `DeSelectPlugin`
  - `RenamePlugin`
  - `ResetPluginName`
  - `SelectAllPlugins`
  - `SelectPlugin`

  The old versions, with `Espm` instead of `Plugin` and `Espms` instead of `Plugins`, are deprecated but retained for backwards compatibility.
  However, wizards that used one of the names listed above for a variable name will break.
- New operator: modulo (`a % b`) - calculates the remainder.
  Shouldn't cause any breakage, but listed here just in case.
