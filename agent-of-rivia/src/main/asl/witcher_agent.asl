max_health(75).
cur_health(75).
strength(25).

facing(top).
position(0, 0).

home(0, 0).
tavern(19, 0).

cur_target(none).



adjacent(X, Y, Xt, Yt) :-
    (X = Xt & (Yt = Y + 1 | Yt = Y - 1))
    |
    (Y = Yt & (Xt = X + 1 | Xt = X - 1)).

healthy_enough :-
    cur_health(CurHP) & max_health(MaxHP) & CurHP >= MaxHP * 0.75.

my_power(P) :-
    cur_health(H) & strength(S) & P = H * S.



//---MAIN GOAL---
!kill_all_monsters.

+!kill_all_monsters : monster(_,_,_,alive) <-
    !ensure_ready;
    !hunt.

+!kill_all_monsters : not monster(_,_,_,alive) <-
    !celebrate;
    !go_home.



//---PREPARATION---
+!ensure_ready : healthy_enough <-
    true.

+!ensure_ready : not healthy_enough <-
    .print("Health is below 75%, I am going to tavern to recover...");
    !go_tavern;
    !heal.

+!go_tavern : tavern(Xt, Yt) <-
    !go_to(Xt, Yt);
    .print("Arrived at tavern.").

+!heal : max_health(MaxHP) <-
    -+cur_health(MaxHP);
    .print("Ate some food, drunk some ale! (HP: ", MaxHP, "/", MaxHP, ")").



//---HUNTING---
+!hunt : monster(Name,Xt,Yt,alive) & monster_power(Name, Power) & my_power(MyPower) & MyPower >= Power <-
    .print("My power is higher!");
    .print("Tracking monster at: (", Xt, ", ", Yt, ")");
    -+cur_target(Name);
    .print("CURRENT TARGET: ", Name, "!");
    !go_to(Xt, Yt).

+!hunt : monster(Name,Xt,Yt,alive) & not monster_power(Name, _) <-
    .print("Tracking monster at: (", Xt, ", ", Yt, ")");
    -+cur_target(Name);
    .print("CURRENT TARGET: ", Name, "!");
    !go_to(Xt, Yt).



//---CELEBRATING---
+!celebrate <-
    .print("Let's celebrate!");
    !go_tavern.

+!go_home : home(Xt, Yt) <-
    !go_to(Xt, Yt);
    .print("I am home!").



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
+neighbour(Agent) : monster(Agent, _, _, alive) & monster_power(Agent, _) & cur_target(Agent) <-
       .print("I returned to ", Agent);
       .print("Long time no see!");
       !fight(Agent).

+neighbour(Agent) : monster(Agent, _, _, alive) & cur_target(Agent) <-
       .print("I tracked ", Agent);
       .print("First contact with enemy...");
       .send(Agent, achieve, disclose_stats).

+monster_stats(H, S)[source(Agent)] : cur_health(My_H) & strength(My_S) <-
     .print("Aha! ", Agent, " has:");
     .print(H, " health and ", S, " strength");
     MonsterPower = H * S;
     MyPower = My_H * My_S;
     !choose_action(Agent, MonsterPower, MyPower).

+!choose_action(Agent, MonsterPower, MyPower) : MonsterPower <= MyPower <-
    .print("I am strong enough to attack ", Agent, "!");
    !fight(Agent).

+!choose_action(Agent, MonsterPower, MyPower) : MonsterPower > MyPower <-
    +monster_power(Agent, MonsterPower);
    .print("I should escape!");
    !kill_all_monsters.



//---FIGHTING---
+!fight(Agent) : not in_battle(_) <-
    +in_battle(Agent);
    .print("I attack!");
    !attack.

+!attack : in_battle(Agent) & strength(S) <-
    .send(Agent, achieve, take_damage(S));
    .print("Aha! I caused ", S, " damage to ", Agent).

+!take_counter_damage(Dmg)[source(Agent)] : in_battle(Agent) & cur_health(HP) <-
    NewHP = HP - Dmg;
    -+cur_health(NewHP);
    !check_battle;
    .print("Argh! Bastard! (HP: ", NewHP, ")").

+!check_battle : cur_health(HP) & HP > 0 & in_battle(Monster) <-
    !attack.

+!check_battle : cur_health(HP) & HP <= 0 & in_battle(Monster) <-
    .print("I am defeated...");
    kill(self);
    -in_battle(Monster).

+!finish_fight[source(Monster)] : max_health(MaxHP) & strength(STR) <-
    !level_up;
    -in_battle(Monster);
    !kill_all_monsters.

+!level_up : max_health(MaxHP) & strength(Str) <-
    NewMaxHP = MaxHP + 75;
    NewStr = Str + 25;
    -+max_health(NewMaxHP);
    -+strength(NewStr);
    .print("LEVEL UP! Max health: ", NewMaxHP, " Strength: ", NewStr).



//---MONSTER CONTRACT BELIEFS---
+monster(Name, X, Y, Status) : Status = alive <-
     .print("I received contract to kill ", Name).

+monster(Name, X, Y, Status) : Status = dead <-
     .print("I finished an contract for ", Name).