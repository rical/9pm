WHY
---
This 9pm TCL Library is designed to address the complexity of interactively managing different
systems simultaneously.

Consider this setup
```
 ___________    _______    _____
|           |  |       |  |     |
| localhost |--| encom |--| clu |
|___________|  |_______|  |_____|
                   |
                ___|___
               |       |
               | flynn |
               |_______|
```


You're running on localhost and you want to start a server on clu and connect
to it from flynn. Then you want to make sure that the client (on flynn) succeeds
and that the hostname of flynn are shown in in the server output on clu.

This is how you could do that with 9pm.

```
shell "server"
ssh "encom"
ssh "clu"
start "./server"

shell "client"
ssh "encom"
ssh "flynn"
set hostname [execute "hostname" 0]
execute "./client" 0

shell "server"
expect {
	"$hostname connected" {
		result OK "$hostname connected to server"
	}
}
set rc [finish]
output INFO "Server returned $rc"
```

CODING STYLE
------------
* Spaces not tabs
* A line should not be longer than 100 chars
* {} embracing are not padded (if {foo} not if { foo })
* No one-line if statements or procedures
* Bool return values are "FALSE" or "TRUE"

NAMESPACE AND SCOPE
-------------------
* Top level namespace (::9pm) should be empty ("fatal" is a current exception).
* Second level namespace names should be unique i.e. not collide with
  anything in TCL/Expect/tcllib.
* Users should be able to use `namespace path ::9pm` to recursively import all
  second level namespaces and there childes.
* Procedures should strive to use variables inside there own namespace.
* All internal references outside of own namespace should be absolute from
  global (::9pm::foo::bar).

RETURN VALUES
-------------
Defined bad return values (1-10 is reserved by the framework)
* 2 - Fatal wrapper trigger

EXECUTION
---------
When executing a 9pm script without the harness you need to tell tcl where
this library is placed. This can be done via the TCLLIBPATH environment
variable. Something like `export TCLLIBPATH='/usr/share/tcltk/ ~/code/9pm'`