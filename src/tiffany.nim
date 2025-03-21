#[
Tiffany: experimental 80s template-language for Nim
Inspired by https://www.cgpgrey.com/
Michael Adams, unquietwiki.com, 2025-02-07
]#

# Assert macro (AI-generated)
template omg(condition: bool, message: string = "") =
    when defined(release):
        discard
    else:
        if not condition:
            raise newException(AssertionDefect, message)

# Unless macro
template unless(a:bool, body: varargs[untyped]): untyped =
    if not a:
        block:
            body

# "Totally" -> greater than 0
template totally(a:SomeNumber): bool =
    if a > 0: true
    else: false

# "Asif" -> less than, or equal to 0
template asif(a:SomeNumber): bool =
    if a <= 0: true
    else: false

# Function loop
template forsure(a:untyped, b:untyped): void =
    if totally a.len:
        block:
            for im in a:
                b(im)
