#!/bin/sh

test_description='custom action chaining functionality

This test covers the contract between todo.sh and custom actions when the actions are chained.
'
. ./test-lib.sh

unset TODO_ACTIONS_DIR
mkdir .todo.actions.d

make_action_chain()
{
	mkdir ".todo.actions.d/$1"
}

make_action()
{
	cat > ".todo.actions.d/$1/$2" <<- EOF
	#!/bin/bash
	echo "custom action $1 order $2"
EOF
	chmod +x ".todo.actions.d/$1/$2"
}

make_chain_action()
{
	cat > ".todo.actions.d/$1/$2" <<- EOF
	#!/bin/bash
	echo "custom action $1 order $2"
	todo.sh $1
EOF
	chmod +x ".todo.actions.d/$1/$2"
}

make_action_chain "foo"

make_action "foo" "1"
test_todo_session 'executable action' <<EOF
>>> todo.sh foo
custom action foo order 1
EOF

chmod -x .todo.actions.d/foo/1
# On Cygwin, clearing the executable flag may have no effect, as the Windows ACL
# may still grant execution rights. In this case, we skip the test.
if [ -x .todo.actions.d/foo/1 ]; then
    SKIP_TESTS="${SKIP_TESTS}${SKIP_TESTS+ }t8010.2"
fi
test_todo_session 'nonexecutable action' <<EOF
>>> todo.sh foo
Usage: todo.sh [-fhpantvV] [-d todo_config] action [task_number] [task_description]
Try 'todo.sh -h' for more information.
=== 1
EOF

make_action_chain "ls"
make_action "ls" "2"
test_todo_session 'overriding built-in action' <<EOF
>>> todo.sh ls
custom action ls order 2

>>> todo.sh command ls
--
TODO: 0 of 0 tasks shown
EOF

make_action_chain "bad"
make_action "bad" "1"
echo "exit 42" >> .todo.actions.d/bad/1
test_todo_session 'failing action' <<EOF
>>> todo.sh bad
custom action bad order 1
=== 42
EOF


make_chain_action "foo" "1"
make_chain_action "foo" "2"
make_action "foo" "4"
test_todo_session 'chain actions' <<EOF
>>> todo.sh foo
custom action foo order 1
custom action foo order 2
custom action foo order 4
EOF

make_action_chain "list"
make_chain_action "list" "1"
make_chain_action "list" "2"
test_todo_session 'overriding built-in action with action chain' <<EOF
>>> todo.sh list
custom action list order 1
custom action list order 2
--
TODO: 0 of 0 tasks shown
EOF

test_done
