#!/usr/bin/env bash
# Mutation check driver for migration/parity.md (phase 5 and 6 of the qa-migrate workflow).
#
# For each mutation id: break one behaviour in the app source, rebuild the bundle, run a suite
# against it, save the raw output and the exact source diff, then restore the source.
# Run from the repository root, on a throwaway branch, with the app served on :8888
# (`node serve.js`, started separately; the static server reads files on every request).
#
#   git switch -c mutation/qa-migrate-check
#   migration/mutate.sh M01 M02 ...          # new suite (Playwright)
#   migration/mutate.sh --old M02+M10        # old suite (Cypress); ids joined with + are applied together
#
# Nothing is committed. The source is restored with `git checkout` after each mutation and the
# bundle is rebuilt from the unmutated source at the end.
set -euo pipefail

OUT=migration/run-output
BRANCH=mutation/qa-migrate-check
SRC="js index.html"

[ "$(git rev-parse --abbrev-ref HEAD)" = "$BRANCH" ] || { echo "not on $BRANCH" >&2; exit 2; }

OLD=0
if [ "${1:-}" = "--old" ]; then OLD=1; shift; fi

apply() {
  case "$1" in
    M01) perl -0pi -e 's/\.value\.trim\(\);/.value;/' js/app.tsx ;;                                  # new todo text is not trimmed
    M02) perl -0pi -e 's/\(ReactDOM\.findDOMNode\(this\.refs\["newField"\]\) as HTMLInputElement\)\.value = \x27\x27;//' js/app.tsx ;; # field not cleared after add
    M03) perl -0pi -e 's/this\.todos = this\.todos\.concat\(\{(.*?)\}\);/this.todos = [{$1}].concat(this.todos);/s' js/todoModel.ts ;; # new todo goes to the top
    M04) perl -0pi -e 's/\{completed: !todo\.completed\}/{completed: todo.completed}/' js/todoModel.ts ;; # toggling an item does nothing
    M05) perl -0pi -e 's/\{completed: checked\}/{completed: todo.completed}/' js/todoModel.ts ;;      # toggle-all does nothing to the items
    M06) perl -0pi -e 's/checked=\{activeTodoCount === 0\}/checked={completedCount > 0}/' js/app.tsx ;; # toggle-all is checked when any item is completed
    M07) perl -0pi -e 's/this\.props\.onDestroy\(\);/;/' js/todoItem.tsx ;;                          # empty edit no longer removes the item
    M08) perl -0pi -e 's/\s*onBlur=\{ e => this\.handleSubmit\(e\) \}//' js/todoItem.tsx ;;          # blur no longer saves the edit
    M09) perl -0pi -e 's/if \(event\.keyCode === ESCAPE_KEY\) \{/if (false) {/' js/todoItem.tsx ;;   # Escape is ignored
    M10) perl -0pi -e 's/var val = this\.state\.editText\.trim\(\);/var val = this.state.editText;/' js/todoItem.tsx ;; # edited text is not trimmed
    M11) perl -0pi -e 's/<strong>\{this\.props\.count\}<\/strong>/<strong>{this.props.count + 1}<\/strong>/' js/footer.tsx ;; # counter is off by one
    M12) perl -0pi -e 's/return !todo\.completed;/return todo.completed;/' js/todoModel.ts ;;         # Clear completed removes the active items
    M13) perl -0pi -e 's/this\.props\.completedCount > 0/this.props.completedCount >= 0/' js/footer.tsx ;; # Clear completed always shown
    M14) perl -0pi -e 's/Clear completed/Clear/' js/footer.tsx ;;                                   # button label changed
    M15) perl -0pi -e 's/Utils\.store\(this\.key, this\.todos\);//' js/todoModel.ts ;;               # nothing is written to localStorage
    M16) perl -0pi -e 's/(case ACTIVE_TODOS:\s*return )!todo\.completed/$1todo.completed/' js/app.tsx ;; # Active filter shows completed items
    M17) perl -0pi -e 's/(case COMPLETED_TODOS:\s*return )todo\.completed/$1!todo.completed/' js/app.tsx ;; # Completed filter shows active items
    M18) perl -0pi -e 's/selected: nowShowing === ACTIVE_TODOS/selected: false/' js/footer.tsx ;;     # Active link is never highlighted
    M19) perl -0pi -e 's/href="#\/completed"/href="#\/completed" onClick={e => { e.preventDefault(); location.replace("#\/completed"); }}/' js/footer.tsx ;; # Completed replaces the history entry
    M20) perl -0pi -e 's/if \(todos\.length\) \{/if (true) {/' js/app.tsx ;;                         # #main rendered with no todos
    M21) perl -0pi -e 's/if \(activeTodoCount \|\| completedCount\) \{/if (true) {/' js/app.tsx ;;  # #footer rendered with no todos
    M22) perl -0pi -e 's/autoFocus=\{true\}/autoFocus={false}/' js/app.tsx ;;                        # new-todo field not focused on load
    M23) perl -0pi -e 's/if \(todos\.length\) \{/if (false) {/' js/app.tsx ;;                        # #main never rendered
    M24) perl -0pi -e 's/this\.todos = this\.todos\.concat\(\{(.*?)\}\);/this.todos = this.todos;/s' js/todoModel.ts ;; # adding a todo does nothing
    M25) perl -0pi -e 's/<\/head>/<style>.info { color: #fff !important; text-shadow: none !important; }<\/style><\/head>/' index.html ;; # white text on the light page background
    M26) perl -0pi -e 's/href="#\/"/href="#\/active"/' js/footer.tsx ;;                             # All link points to Active
    M27) perl -0pi -e 's/(else if \(event\.keyCode === ENTER_KEY\) \{\s*)this\.handleSubmit\(event\);/$1/' js/todoItem.tsx ;; # Enter no longer saves the edit
    M28) perl -0pi -e 's/\{completed: !todo\.completed\}/{completed: true}/' js/todoModel.ts ;;       # an item can be completed but not un-completed
    M29) perl -0pi -e 's/<\/head>/<style>.todo-list li.editing .view { display: block !important; }<\/style><\/head>/' index.html ;; # row controls stay visible while editing
    M30) perl -0pi -e 's/this\.props\.onCancel\(event\);/this.handleSubmit(event);/' js/todoItem.tsx ;; # Escape saves the edit instead of cancelling
    M31) perl -0pi -e 's/Clear completed/Clear completed items/' js/footer.tsx ;;                   # button label longer, accessible name still contains the old one
    M32) perl -0pi -e 's/if \(activeTodoCount \|\| completedCount\) \{/if (false) {/' js/app.tsx ;; # #footer never rendered
    M33) perl -0pi -e 's/completed: this\.props\.todo\.completed,/completed: false,/' js/todoItem.tsx ;; # row never gets the completed class (checkbox state is still right)
    *) echo "unknown mutation $1" >&2; exit 2 ;;
  esac
}

for set in "$@"; do
  name="${set//+/-}"
  for id in ${set//+/ }; do apply "$id"; done
  if git diff --quiet -- $SRC; then echo "$set did not change the source" >&2; exit 1; fi
  git diff -- $SRC > "$OUT/mutation-$name.diff"
  if ! npm run build > "$OUT/.build.log" 2>&1; then cat "$OUT/.build.log"; git checkout -- $SRC; exit 1; fi
  if [ "$OLD" = 1 ]; then
    env -u ELECTRON_RUN_AS_NODE npx cypress run --browser electron > "$OUT/cypress-mutation-$name.txt" 2>&1 || true
  else
    npx playwright test --reporter=list > "$OUT/mutation-$name.txt" 2>&1 || true
  fi
  git checkout -- $SRC
  echo "$set done"
done
npm run build > "$OUT/.build.log" 2>&1
rm -f "$OUT/.build.log"
