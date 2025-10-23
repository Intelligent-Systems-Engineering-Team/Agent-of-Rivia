facing(top).
home(0, 0).
position(0, 0).
status(hunting).
obstacle(Dir) :- robot(Dir).

opposite(top, bottom).
opposite(left, right).
opposite(X, Y) :- opposite(Y, X).

health(100).

monster(3, 3).
monster(5, 7).
monster(10, 3).



!kill_all_monsters.

+!kill_all_monsters <-
    !explore;
    !go_home.


+!explore : not(status(hunting)) <- true.

+!explore : status(hunting) & monster(Xt, Yt) & not busy <-
    -+busy;
    !go_to(Xt, Yt);
    -busy;
    !explore.

+!explore : not monster(_,_) <-
    .print("All monsters are dead!");
    -+status(resting).

-!explore : status(hunting) <-
    .print("go_to failed");
    !explore.


+!go_home : home(Xt, Yt) <-
    !go_to(Xt, Yt);
    .print("Arrived home").


+position(X, Y) <- .print("BEL: (", X, ", ", Y, ")").


+!go(Direction) <-
    move(Direction);
    utils.update_pose(Direction).

-!go(Direction) <-
    !go(Direction).


+!go_to(Xt, Yt) : position(Xt, Yt) <-
    -monster(Xt, Yt);
    .print("Monster killed").


+!go_to(Xt, Yt) : position(X, Y) & X < Xt & facing(top) <-
    !go(right);
    !go_to(Xt, Yt).

+!go_to(Xt, Yt) : position(X, Y) & X < Xt & facing(right) <-
    !go(forward);
    !go_to(Xt, Yt).

+!go_to(Xt, Yt) : position(X, Y) & X < Xt & facing(bottom) <-
    !go(left);
    !go_to(Xt, Yt).

+!go_to(Xt, Yt) : position(X, Y) & X < Xt & facing(left) <-
    !go(backward);
    !go_to(Xt, Yt).


+!go_to(Xt, Yt) : position(X, Y) & X > Xt & facing(top) <-
    !go(left);
    !go_to(Xt, Yt).

+!go_to(Xt, Yt) : position(X, Y) & X > Xt & facing(right)<-
    !go(backward);
    !go_to(Xt, Yt).

+!go_to(Xt, Yt) : position(X, Y) & X > Xt & facing(bottom)<-
    !go(right);
    !go_to(Xt, Yt).

+!go_to(Xt, Yt) : position(X, Y) & X > Xt & facing(left)<-
    !go(forward);
    !go_to(Xt, Yt).


+!go_to(Xt, Yt) : position(X, Y) & Y > Yt & facing(top) <-
    !go(forward);
    !go_to(Xt, Yt).

+!go_to(Xt, Yt) : position(X, Y) & Y > Yt & facing(right) <-
    !go(left);
    !go_to(Xt, Yt).

+!go_to(Xt, Yt) : position(X, Y) & Y > Yt & facing(bottom) <-
    !go(backward);
    !go_to(Xt, Yt).

+!go_to(Xt, Yt) : position(X, Y) & Y > Yt & facing(left) <-
    !go(right);
    !go_to(Xt, Yt).


+!go_to(Xt, Yt) : position(X, Y) & Y < Yt & facing(top) <-
    !go(backward);
    !go_to(Xt, Yt).

+!go_to(Xt, Yt) : position(X, Y) & Y < Yt & facing(right) <-
    !go(right);
    !go_to(Xt, Yt).

+!go_to(Xt, Yt) : position(X, Y) & Y < Yt & facing(bottom) <-
    !go(forward);
    !go_to(Xt, Yt).

+!go_to(Xt, Yt) : position(X, Y) & Y < Yt & facing(left) <-
    !go(left);
    !go_to(Xt, Yt).

