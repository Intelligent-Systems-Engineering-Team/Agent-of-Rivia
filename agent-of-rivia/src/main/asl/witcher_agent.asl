facing(top).
position(0, 0).
status(hunting).
obstacle(Dir) :- robot(Dir).

opposite(top, bottom).
opposite(left, right).
opposite(X, Y) :- opposite(Y, X).

target(0, 0).

!kill_all_monsters.

+!kill_all_monsters <-
    !explore;
    !come_back.


+!explore : not(status(hunting)) <- true.

+!explore : status(hunting) & target(Xt, Yt) <-
    .print("before go_to");
    !go_to(Xt, Yt);
    .print("after go_to").
-!explore : status(hunting) <-
    !change_direction;
    .print("go_to failed");
    !explore.


+!come_back : status(rescuing(Agent)) & neighbour(Agent) <-
    !go_towards_home;
    !come_back.
+!come_back : status(rescuing(Agent)) & not(neighbour(Agent)) <-
    .wait({ +neighbour(Agent) });
    !come_back.


+!go_on(0) <- true.
+!go_on(N) : N > 0 <-
    !go(forward);
    !go_on(N - 1).
+!go_on(_) <- true.

+!change_direction <-
    .print("Let's turn back");
    !go(backward).
+!change_direction <-
    .print("Let's turn right");
    !go(right).
+!change_direction <-
    .print("Let's turn left");
    !go(left).
+!change_direction <-
    .random(X);
    if (X >= 0.5) {
        .print("Let's turn right");
        !go(right)
    } else {
        .print("Let's turn left");
        !go(left)
    }.

+!go(Direction) <-
    move(Direction);
    utils.update_pose(Direction).
-!go(Direction) <-
    !go(Direction).

+position(X, Y) <- .print("I'm in (", X, ", ", Y, ")").

+neighbour(Agent) : not(status(rescuing(Agent))) <-
    .print("Found ", Agent, "! Starting rescue.");
    .send(Agent, tell, go_home);
    -+status(rescuing(Agent)).




+!go_to(Xt, Yt) : position(Xt, Yt) <-
    .print("Arrived at target (", Xt, ", ", Yt, ")").

+!go_to(Xt, Yt) : position(X, Y) & X < Xt <-
    !go(right);
    !go_to(Xt, Yt).

+!go_to(Xt, Yt) : position(X, Y) & X > Xt <-
    !go(left);
    !go_to(Xt, Yt).

+!go_to(Xt, Yt) : position(X, Y) & Y < Yt <-
    !go(top);
    !go_to(Xt, Yt).

+!go_to(Xt, Yt) : position(X, Y) & Y > Yt <-
    !go(bottom);
    !go_to(Xt, Yt).