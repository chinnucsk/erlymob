Erlymob
=======

[Erlymob](http://www.erlymob.com) is a Twitter-based event aggregator. It
collects tweets in real time and distributes them to those who have the best
opportunity to attend. Flash mobs, local deals, activism - everyone can find
something social.

Erlymob was designed to run with the frontend and backend running in different
Erlang VMs and so far has only been tested with Ubuntu Linux and Erlang R15B.
To test it you'll need to start two different Erlang shells on the same
computer. The two components in the system are named `emob` (backend) and
`emob_ui` (frontend). The instructions to build, deploy and run the system are
the following:

emob
----

*Build*:

```text
cd emob
make deps
make
make console
```

*Set Up (only needs to be done once per fresh install)*:

```erlang
emob:setup().
```

*Deploy*:

```erlang
emob:start().
```

emob_ui
-------

*Build*:

```text
cd emob_ui
make deps
make compile
```

*Deploy*:

```text
./init-dev.sh
```

Accessing the web interface
---------------------------

To access the web interface with a web browser locally you can go to
[http://localhost:3000/](http://localhost:3000/) or you can try the public web
site on [http://erlymob.com](http://erlymob.com).

Posting a new mob
-----------------

To post a new mob, send a tweet to @erlymob_test containing the text you want
to post.  It will then be visible on your home screen in Erlymob.
