facing(top).
home(0, 0).
position(0, 0).
status(hunting).

health(100).
strength(50).



obstacle(Dir) :- robot(Dir).
opposite(top, bottom).
opposite(left, right).
opposite(X, Y) :- opposite(Y, X).

adjacent(X, Y, Xt, Yt) :-
    (X = Xt & (Yt = Y + 1 | Yt = Y - 1))
    | (Y = Yt & (Xt = X + 1 | Xt = X - 1)).



!kill_all_monsters.

+!kill_all_monsters <-
    !hunt;
    !go_home.


+!hunt : not(status(hunting)) <- true.

+!hunt : status(hunting) & monster(Xt, Yt, alive) & not busy <-
    -+busy;
    !go_to(Xt, Yt);
    -busy;
    !hunt.

+!hunt : not monster(_,_,alive) <-
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
    .print("Move failed, retrying...");
    !go(Direction).

+!go_to(Xt, Yt) : position(X, Y) & adjacent(X, Y, Xt, Yt) <-
    .print("Stopped one cell before monster at (", Xt, ",", Yt, ")").


+!go_to(Xt, Yt) : position(Xt, Yt) <-
    .print("Arrived at target (", Xt, ",", Yt, ")");
    -monster(Xt, Yt).

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

+neighbour(Agent) : status(hunting) & monster(Xt, Yt, alive) <-
       .print("I tracked: ", Agent);
       !analyse_monster(Agent).


+!analyse_monster(Agent) <-
    .send(Agent, achieve, show_level).


+monster_level(Health, Strength)[source(M)] : health(HP)  & strength(STR) <-
    .print("Monster has: [HP ", Health, "] [STR ", Strength, "]");
    MonsterLevel = Health / Strength;
    MyLevel = HP / STR;
    .print("Monster level is: ", MonsterLevel);
    .print("My level is: ", MyLevel);
    !make_decision(M, MonsterLevel, MyLevel).


+!make_decision(Monster, MonsterLevel, MyLevel) : MonsterLevel <= MyLevel & strength(STR) <-
    .print("Decided to attack monster: ", Monster);
    !fight(Monster).



//---ESCAPE---
//---ESCAPE---
//---ESCAPE---

+!make_decision(Monster, MonsterLevel, MyLevel) : MonsterLevel > MyLevel <-
    .print("Decided to escape: ", Monster);
    -+status(escaping);
    // Find ANY alive monster, not just adjacent ones
    if (monster(MX, MY, alive)) {
        !escape_from(MX, MY)
    } else {
        .print("No monster found - returning to hunting");
        -+status(hunting)
    }.

// Escape plan - move away until safe distance
+!escape_from(MX, MY) : position(X, Y) & adjacent(X, Y, MX, MY) <-
    .print("🏃 Adjacent to monster at (", MX, ",", MY, "), retreating...");
    !deterministic_retreat(MX, MY);
    !escape_from(MX, MY).

+!escape_from(MX, MY) <-
    .print("✓ Escape successful — no longer adjacent to (", MX, ",", MY, ")");
    -monster(MX, MY, alive);
    +monster(MX, MY, dead);
    -+status(hunting).

// Deterministic retreat - prioritize moving away from monster
+!deterministic_retreat(MX, MY) : position(X, Y) & X > MX & free(right) <-
    .print("Escaping RIGHT (away from monster)");
    !orient(right);
    !go(forward).

+!deterministic_retreat(MX, MY) : position(X, Y) & X < MX & free(left) <-
    .print("Escaping LEFT (away from monster)");
    !orient(left);
    !go(forward).

+!deterministic_retreat(MX, MY) : position(X, Y) & Y > MY & free(bottom) <-
    .print("Escaping DOWN (away from monster)");
    !orient(bottom);
    !go(forward).

+!deterministic_retreat(MX, MY) : position(X, Y) & Y < MY & free(top) <-
    .print("Escaping UP (away from monster)");
    !orient(top);
    !go(forward).

// Fallback: try any free direction
+!deterministic_retreat(MX, MY) : free(left) <-
    .print("Escaping LEFT (fallback)");
    !orient(left);
    !go(forward).

+!deterministic_retreat(MX, MY) : free(right) <-
    .print("Escaping RIGHT (fallback)");
    !orient(right);
    !go(forward).

+!deterministic_retreat(MX, MY) : free(top) <-
    .print("Escaping UP (fallback)");
    !orient(top);
    !go(forward).

+!deterministic_retreat(MX, MY) : free(bottom) <-
    .print("Escaping DOWN (fallback)");
    !orient(bottom);
    !go(forward).

+!deterministic_retreat(_,_) <-
    .print("⚠️ No escape direction available — trapped!");
    -+status(hunting).

// Define free directions
free(left) :- not obstacle(left).
free(right) :- not obstacle(right).
free(top) :- not obstacle(top).
free(bottom) :- not obstacle(bottom).
//---FIGHTING---
+!fight(Monster) : monster(X, Y, alive) & strength(STR) <-
    .print("Fighting monster: ", Monster);
    .send(Monster, achieve, get_damage(STR));
    .send(Monster, achieve, fight_back);
    !fight(Monster).

+!fight(Monster) : monster(X, Y, dead) <-
    .print("Defeated: ", Monster).





+monster(X, Y, Status) : true <-
     .print("BELIEF RECEIVED: monster(", X, ",", Y, ",", Status, ")").


//---GOING HOME---

+!go_home : home(Xt, Yt) <-
    !go_to(Xt, Yt);
    .print("Arrived home").
