# Defining redirects

## Definitions

- **Standard redirects** - Redirect old URLs that no longer exist under the
  containing docset to the new URLs. For example, updating the 1.20 redirect
  file (`/vault/v1.20.x/redirects.jsonc`) to send requests for `path/pageA` in
  the v1.20 docset to `path/pageB` in the v1.20 docset.

- **Versioned redirects** - Redirect URLs that no longer exist under the
  containing docset to a URL in a different docset. For example, updating
  the 1.20 redirect file (`/vault/v1.20.x/redirects.jsonc`) to send invalid
  requests for `path/upgrade-to-1.18` in the v1.20 docset to `path/upgrade-to-1.18`
  in the v1.18 docset (`vault/docs/v1.18.x/path/upgrade-to-1.18`).
  You can use versioned redirects to help the version picker find the right page
  across versions.

- **Backfacing redirects** - Redirect versioned URLs that use new paths from the
  containing docset to an appropriate URL in another docset version. For example,
  updating the 1.20 redirect file (`/vault/v1.20.x/redirects.jsonc`) to send
  invalid requests for `path/important-changes` in the 1.18.x docset
  (`vault/docs/v1.18.x/path/important-changes`) to `path/upgrade-to-1.18` in the
  v1.18 docset (`vault/docs/v1.18.x/path/upgrade-to-1.18`).
  You can use backfacing redirects to keep URL formatting consistent in
  long-living pages across multiple versions. For example, the Vault change
  tracker (`/vault/docs/updates/change-tracker`) uses
  `/vault/docs/<version>/updates/important-changes` URL references for all the
  important changes links to simplify maintenance for contributors.

## Path parameters and regex

You can define and name parameters in the source path and use the matched value
your in destination path definitions. Parameter definitions include string
constants, predefined character classes, and regex expressions that match to
multiple paths using non-capture groups. Use `?:` to mark the start of a
non-capture group.

Special character | Description
----------------- | -----------
`(` and `)`       | Wraps parameter definitions and regex definitions.
`{ min, max }`    | Matches the pattern `min` or more times up to an optional `max` number of times
`[` and `]`       | Define a range of characters or strings
`\|`              | Defines alternatives in a range or non-capture group<sup>1</sup>
`\`               | Indicates a predefined character class
`^`               | Matches a non-capture group to the start of the string
`.`               | Matches to any single character
`:`               | Start a non-capture group
`*`               | Matches the pattern zero or more times
`+`               | Matches the pattern one or more times
`-`               | Defines a **single-character** range (numbers or letters)
`?`               | Match the pattern zero or one times
`$`               | Match to the end of the string
`!`               | Start a negative look-ahead non-capture group

<sup>1</sup>: the actual character is `|`, but the markdown requires an escape character to render properly in GitHub

To escape special characters in your regex expression, use `\\`. For example, to
escape the `.` character in versioned URLs, use `\\.`.

### Predefined character classes

-`\d` - Matches any digit (0-9).
-`\D` - Matches any non-digit.
-`\w` - Matches any word character (alphanumeric and underscore).
-`\W` - Matches any non-word character (including most special characters).
-`\s` - Matches any whitespace character.
-`\S` - Matches any non-whitespace character.


### Example regex strings

Parameter definition (:slug)      | :slug value
--------------------------------- | -----------------
:slug(v1\\.(?:12|13)\\.x)         | v1.12.x, v1.13.x
v:slug(1\\.(?:12|13)\\.x)         | 1.12.x, 1.13.x
v:slug(1\\.(?:12|13)).x           | 1.12, 1.13
:slug(path1(?:\\-abc$)?)          | "path1" or "path1-abc"
:slug((?!path1$).*)               | a string that does not match "path1"
:slug((?!path1$|!path2$).*)       | a string that does not match "path1" or "path2"
:slug(\\d{1,})                    | a string of length 1 or more that only contains digits
:slug(\\d{1,4})                   | a string of length 1, 2, 3, or 4 that only contains digits
:slug(release-(?:[1-5]))          | a string starting with "release-" followed by 1, 2, 3, 4, or 5
:slug(release-(?:[[0-9]|10|11]))  | a string starting with "release-" followed by any number between 0 and 11



## Examples

Standard redirect:

```json
  {
    "source": "/vault/docs/old/path",
    "destination": "/vault/docs/new/path",
    "permanent": true,
  }
```

Redirect all child paths:

```json
  {
    "source": "/vault/docs/old/path/:slug(.*)",
    "destination": "/vault/docs/new/path/:slug",
    "permanent": true,
  }
```

Redirect for a specific version:

```json
  {
    "source": "/vault/docs/<version_string>/old/path",
    "destination": "/vault/docs/<version_string>/new/path",
    "permanent": true,
  }
```

Use regex to redirect versioned URLs for v1.12.x and v1.13.x:

```json
  {
    "source": "/vault/docs/:version(v1\\.(?:12|13)\\.x)/new/path",
    "destination": "/vault/docs/:version/old/path",
    "permanent": true,
  }
```

Use regex to pull out the number portion (`1.N`) of a versioned URL that looks
like `vault/docs/v1.N.x/path/to/page`:

```json
  {
    "source": "/vault/docs/v:version(1\\.(?:9|10|11|12|13|14|15|16|17|18)\\.x)/updates/important-changes",
    "destination": "/vault/docs/v:version/upgrading/upgrade-to-:version",
    "permanent": true
  },
```

Use regex to redirect all `docs/agent/*` paths except `docs/agent/autoauth/*` to
`/agent-and-proxy/agent/*`:

```json
  {
    "source": "/vault/docs/agent/:slug((?!autoauth$).*)",
    "destination": "/vault/docs/agent-and-proxy/agent/:slug",
    "permanent": true
  },
```
