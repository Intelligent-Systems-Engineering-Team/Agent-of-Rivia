


//---INITIAL BELIEFS---

facing(top).
home(0, 0).
position(0, 0).
status(hunting).
tavern(19, 0).
health(95).
strength(25).

adjacent(X, Y, Xt, Yt) :-
    (X = Xt & (Yt = Y + 1 | Yt = Y - 1))
    | (Y = Yt & (Xt = X + 1 | Xt = X - 1)).



//---MAIN GOAL---

!kill_all_monsters.

+!kill_all_monsters <-
    !hunt;
    !celebrate;
    !go_home.

-!kill_all_monsters <-
    .print("Failed to kill all monsters").
    
    
+!hunt : health(H) & H < 100 <-
    .print("Health is low, heading to tavern...");
    !go_tavern;
    !rest;
    !hunt.

+!hunt : status(hunting) & monster(_,Xt,Yt,alive) <-
    .print("Investigating location: (", Xt, ",", Yt, ")");
    !go_to(Xt, Yt);
    !hunt.

+!hunt : not monster(_,_,_,alive) <-
    .print("All monsters are dead!");
    -+status(celebrating).

-!hunt <-
    .print("Hunting failed");
    !hunt.

+!celebrate <-
    .print("TIME TO PARTY!");
    !go_tavern;
    .wait(5000).

//---WALKING---

+!go(Direction) <-
    move(Direction);
    utils.update_pose(Direction).

-!go(Direction) <-
    .print("Move failed, retrying...");
    !go(Direction).


+!go_to(Xt, Yt) : position(X, Y) & monster(_, Xt, Yt, alive) & adjacent(X, Y, Xt, Yt) <-
    true.

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

+!go_tavern : tavern(Xt, Yt) <-
    !go_to(Xt, Yt);
    .print("Arrived at tavern.").

+!rest <-
    -health(_);
    +health(100);
    .print("Rested at the tavern, Health restored to 100").

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

+neighbour(Agent) : status(hunting) & monster(Agent, Xt, Yt, alive) <-
       .print("I tracked: ", Agent);
       !analyse_monster(Agent).


+!analyse_monster(Agent) <-
    .send(Agent, achieve, show_level).


+monster_level(Health, Strength)[source(M)] : health(HP) <-
    .print("Monster has: [HP ", Health, "] [STR ", Strength, "]");
    MonsterLevel = Health / Strength;
    MyLevel = HP / STR;
    .print("Monster level is: ", MonsterLevel);
    .print("My level is: ", MyLevel);
    !make_decision(M, MonsterLevel, MyLevel).


+!make_decision(Monster, MonsterLevel, MyLevel) : MonsterLevel <= MyLevel & strength(STR) <-
    .print("Decided to attack monster: ", Monster);
    !fight(Monster).

+!make_decision(Monster, MonsterLevel, MyLevel) : MonsterLevel > MyLevel <-
    .print("Decided to escape: ", Monster).



//---FIGHTING---

+!fight(Monster) : monster(Monster, X, Y, alive) & strength(STR) <-
    .print("Fighting monster: ", Monster);
    .send(Monster, achieve, get_damage(STR));
    .send(Monster, achieve, fight_back);
    !fight(Monster).

+!fight(Monster) : monster(Monster, X, Y, dead) <-
    .print("Defeated: ", Monster).


+monster(Name, X, Y, Status) : true <-
     .print("BELIEF RECEIVED: ", Name, ",", Status).



//---GOING HOME---

+!go_home : home(Xt, Yt) <-
    .print("start going home");
    !go_to(Xt, Yt);
    .print("Arrived home").
