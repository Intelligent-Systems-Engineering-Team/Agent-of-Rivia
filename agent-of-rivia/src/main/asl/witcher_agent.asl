facing(top).

position(0, 0).
home(0, 0).
tavern(19, 0).
health(75).
max_health(75).
strength(25).

adjacent(X, Y, Xt, Yt) :-
    (X = Xt & (Yt = Y + 1 | Yt = Y - 1))
    | (Y = Yt & (Xt = X + 1 | Xt = X - 1)).



!kill_all_monsters.

+!kill_all_monsters : monster(_,_,_,alive) <-
    !hunt.

+!kill_all_monsters : not monster(_,_,_,alive) <-
    !celebrate;
    !go_home.

-!kill_all_monsters <-
    .print("Failed: kill all monsters").



+!hunt : health(H) & max_health(MaxHP) & H < MaxHP * 0.75  <-
    !go_tavern;
    !heal;
    !kill_all_monsters.

+!hunt : monster(_,Xt,Yt,alive) <-
    !track_monster(Xt, Yt).


+!hunt : not monster(_,_,_,alive) <-
    .print("All monsters are dead!").

+!hunt : in_battle(_) <-
    .print("Already in battle, stop hunting for now.").

-!hunt <-
    .print("Failed: hunt").



+!track_monster(Xt, Yt) <-
    .print("Tracking monster at: (", Xt, ", ", Yt, ")");
    !go_to(Xt, Yt).

+!celebrate <-
    .print("Let's celebrate!");
    !go_tavern;
    .wait(5000).

+!go_tavern : tavern(Xt, Yt) <-
    !go_to(Xt, Yt);
    .print("Arrived at tavern.").

+!heal : max_health(MaxHP) <-
    -+health(MaxHP);
    .print("Ate some food, drunk some ale! (HP: 100)").

+!go_home : home(Xt, Yt) <-
    !go_to(Xt, Yt);
    .print("Arrived home").



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



+!orient(Dir) : facing(Dir) <- true.

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



//---MONSTER ESTIMATION---
+neighbour(Agent) : monster(Agent, _, _, alive) <-
       .print("I tracked ", Agent);
       .print("First contact with enemy...");
       .send(Agent, achieve, disclose_stats).

+monster_stats(H, S)[source(Agent)] : health(My_H) & strength(My_S) <-
     .print("Aha! ", Agent, " has:");
     .print(H, " health and ", S, " strength");
     MonsterPower = H * S;
     MyPower = My_H * My_S;
     !make_decision(Agent, MonsterPower, MyPower).

+!make_decision(Agent, MonsterPower, MyPower) : MonsterPower <= MyPower <-
    .print("I am strong enough to attack ", Agent, "!");
    !fight(Agent).

+!make_decision(Agent, MonsterPower, MyPower) : MonsterPower > MyPower <-
    .print("Decided to escape: ", Agent).



//---FIGHTING---
+!fight(Agent) : not in_battle(_) <-
    .print("I start a battle!");
    +in_battle(Agent);
    !attack.

+!attack : in_battle(Agent) & strength(S) <-
    .print("I caused ", S, " damage to ", Agent);
    .send(Agent, achieve, take_damage(S)).

+!counter_damage(Dmg)[source(Agent)] : in_battle(Agent) & health(HP) <-
    NewHP = HP - Dmg;
    .print("Argh! Bastard! (HP: ", NewHP, ")");
    -health(HP);
    +health(NewHP);
    !check_battle.

+!check_battle : health(HP) & HP > 0 & in_battle(Monster) <-
    !attack.

+!check_battle : health(HP) & HP <= 0 & in_battle(Monster) <-
    .print("I am defeated...");
    kill(self);
    -in_battle(Monster).

+!finish_fight[source(Monster)] : max_health(MaxHLTH) & strength(STR) <-
    NewMaxHlth = MaxHLTH + 75;
    NewStr = STR + 25;
    -+max_health(NewMaxHlth);
    -+strength(NewStr);
    .print("LEVEL UP! Max health: ", NewMaxHlth, " Strength: ", NewStr);
    
    -in_battle(Monster);
    !kill_all_monsters.



//---MONSTER CONTRACT BELIEFS---
+monster(Name, X, Y, Status) : Status = alive <-
     .print("I received contract to kill ", Name).

+monster(Name, X, Y, Status) : Status = dead <-
     .print("I finished an contract for ", Name).
