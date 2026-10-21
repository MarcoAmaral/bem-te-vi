# The README demo (plan 049). Render it with demo/record.sh, which prepares the throwaway project
# and the environment this tape expects; `vhs demo/bem-te-vi.tape` alone fails at Require or at
# the hidden setup.
#
# One clip, one live run: install the package, show the story, run /qa-cases in Claude Code's
# print mode, list the cases it wrote, run the package's format hook on them. The only cut is the
# model's wait (about 30 seconds of a blank screen), hidden between Hide and Show below.

Output demo/bem-te-vi.gif
Output demo/bem-te-vi.mp4
Output demo/bem-te-vi.webm

Require bem-te-vi
Require claude
Require node

Set Shell "bash"
Set FontSize 18
Set Width 1200
Set Height 760
Set Padding 24
Set Framerate 24
Set TypingSpeed 45ms

# Hidden setup: bare prompt, cd into the project, isolated `claude` wrapper (see demo/shell.sh).
Hide
Type `source "$DEMO_SHELL" && clear`
Enter
Sleep 1s
Show

Sleep 800ms
Type "bem-te-vi init --editor claude"
Sleep 500ms
Enter
Sleep 5s

Type "cat story.md"
Sleep 400ms
Enter
Sleep 6s

Hide
Type "clear"
Enter
Sleep 500ms
Show

Type `claude -p --model sonnet "/qa-cases story.md. Save the test cases as TC-CART.md."`
Sleep 600ms
Enter
Sleep 2s

# The model's wait, cut: wait off screen until the prompt comes back.
Hide
Wait@240s /^\$\s*$/
Show
Sleep 9s

Type "grep '^## TC-' TC-CART.md"
Sleep 400ms
Enter
Sleep 4s

Type ".claude/hooks/validate-tc-format.sh TC-CART.md"
Sleep 400ms
Enter
Sleep 6s
