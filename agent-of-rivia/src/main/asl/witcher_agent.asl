facing(top).
home(0, 0).
position(0, 0).
status(hunting).
health(100).

monster(3, 3).
monster(5, 7).
monster(10, 3).


obstacle(Dir) :- robot(Dir).
opposite(top, bottom).
opposite(left, right).
opposite(X, Y) :- opposite(Y, X).




!kill_all_monsters.

+!kill_all_monsters <-
    !hunt;
    !go_home.


+!hunt : not(status(hunting)) <- true.

+!hunt : status(hunting) & monster(Xt, Yt) & not busy <-
    -+busy;
    !go_to(Xt, Yt);
    -busy;
    !hunt.

+!hunt : not monster(_,_) <-
    .print("All monsters are dead!");
    -+status(resting).

-!hunt : status(hunting) <-
    .print("go_to failed");
    !hunt.



//---WALKING---

+!go(Direction) <-
    move(Direction);
    utils.update_pose(Direction).

-!go(Direction) <-
    !go(Direction).

+!go_to(Xt, Yt) : position(Xt, Yt) <-
    -monster(Xt, Yt);
    .print("Monster killed").

+!go_to(Xt, Yt) : position(X, Y) & X < Xt <-
    !orient(right);
    !go(forward);
    !go_to(Xt, Yt).

+!go_to(Xt, Yt) : position(X, Y) & X > Xt <-
    !orient(left);
    !go(forward);
    !go_to(Xt, Yt).

+!go_to(Xt, Yt) : position(Xt, Y) & Y < Yt <-
    !orient(bottom);
    !go(forward);
    !go_to(Xt, Yt).

+!go_to(Xt, Yt) : position(Xt, Y) & Y > Yt <-
    !orient(top);
    !go(forward);
    !go_to(Xt, Yt).

+!orient(Dir) : facing(Dir) <-
    true.

+!orient(right) : facing(top)    <- !go(right).
+!orient(right) : facing(bottom) <- !go(left).
+!orient(right) : facing(left)   <- !go(backward).

+!orient(left)  : facing(top)    <- !go(left).
+!orient(left)  : facing(bottom) <- !go(right).
+!orient(left)  : facing(right)  <- !go(backward).

+!orient(top)   : facing(right)  <- !go(left).
+!orient(top)   : facing(left)   <- !go(right).
+!orient(top)   : facing(bottom) <- !go(backward).

+!orient(bottom): facing(top)    <- !go(backward).
+!orient(bottom): facing(left)   <- !go(left).
+!orient(bottom): facing(right)  <- !go(right).

+position(X, Y) <- .print("I am in: (", X, ", ", Y, ")").



//---NEIGHBOUR INTERACTION---

+neighbour(Agent) : status(hunting) <-
    .print("Hello ", Agent, "! I'll kick your ass!");
    .send(Agent, tell, fight).



//---GOING HOME---

+!go_home : home(Xt, Yt) <-
    !go_to(Xt, Yt);
    .print("Arrived home").