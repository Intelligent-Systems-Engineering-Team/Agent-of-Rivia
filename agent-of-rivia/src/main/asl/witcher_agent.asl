max_health(75).
cur_health(75).
strength(25).

facing(top).
position(0, 0).

home(0, 0).
tavern(19, 0).

cur_target(none).

heal_threshold(0.75).


// ---------- DERIVED BELIEFS ----------
adjacent(X, Y, Xt, Yt) :-
    (X = Xt & (Yt = Y + 1 | Yt = Y - 1))
    |
    (Y = Yt & (Xt = X + 1 | Xt = X - 1)).

healthy_enough :-
    cur_health(CurHP) &
    max_health(MaxHP) &
    heal_threshold(ThresholdHP) &
    CurHP >= MaxHP * ThresholdHP.

my_power(P) :-
    cur_health(H) & 
    strength(S) & 
    P = H * S.

monster_power(Name, Power) :-
    monster(Name, _, _, _, alive, HP, STR) & 
    Power = HP * STR.


// ---------- MAIN GOAL ----------
!kill_all_monsters.

+!kill_all_monsters : monster(_,_,_,_,alive,_,_) <-
    !ensure_ready;
    !hunt.

+!kill_all_monsters : not monster(_,_,_,_,alive,_,_) <-
    !celebrate;
    !go_home.


// ---------- PREPARATION ----------
+!ensure_ready : healthy_enough <- true.

+!ensure_ready : not healthy_enough <-
    .print("Health is below threshold, I am going to tavern...");
    !go_tavern;
    !heal.

+!go_tavern : tavern(X, Y) <-
    !go_to(X, Y);
    .print("Arrived at tavern.").

+!heal : max_health(MaxHP) <-
    -+cur_health(MaxHP);
    .print("Ate some food, drunk some ale! (HP: ", MaxHP, "/", MaxHP, ")").


// ---------- HUNTING ----------
can_hunt(Name) :-
    monster_power(Name, MonsterPower) &
    my_power(MyPower) &
    MyPower >= MonsterPower.

can_hunt(Name) :-
    not monster_power(Name, _).

+!hunt : monster(Name, _, X, Y, alive, _, _) & can_hunt(Name) <-
    !set_target(Name);
    !track_target(X, Y).

+!hunt : monster(Name, _, _, _, alive, _, _) & not can_hunt(Name) <-
    .print("Monster ", Name, " is too strong, skipping target...");
    !kill_all_monsters.

+!set_target(Name) <-
    -+cur_target(Name);
    .print("My next target is ", Name, "!").

+!track_target(X, Y) <-
    .print("Tracking monster at: (", X, ", ", Y, ")");
    !go_to(X, Y).


// ---------- CELEBRATING ----------
+!celebrate <-
    .print("Let's celebrate!");
    !go_tavern.

+!go_home : home(Xt, Yt) <-
    !go_to(Xt, Yt);
    .print("I am home!");
    .print("...zzzzzz").


// ---------- MOVEMENT ----------
+!go(Direction) <-
    move(Direction);
    utils.update_pose(Direction).

-!go(Direction) <-
    .print("Move failed, retrying...");
    !go(Direction).

+!go_to(Xt, Yt) : position(X, Y) & monster(_, _, Xt, Yt, alive, _, _) & adjacent(X, Y, Xt, Yt) <-
    true.

+!go_to(Xt, Yt) : position(Xt, Yt) <-
    true.

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


// ---------- ORIENTATION ----------
+!orient(Dir) : facing(Dir) <- true.

+!orient(right)  : facing(top)    <- !turn_right.
+!orient(right)  : facing(bottom) <- !turn_left.
+!orient(right)  : facing(left)   <- !turn_back.

+!orient(left)   : facing(top)    <- !turn_left.
+!orient(left)   : facing(bottom) <- !turn_right.
+!orient(left)   : facing(right)  <- !turn_back.

+!orient(top)    : facing(right)  <- !turn_left.
+!orient(top)    : facing(left)   <- !turn_right.
+!orient(top)    : facing(bottom) <- !turn_back.

+!orient(bottom) : facing(top)    <- !turn_back.
+!orient(bottom) : facing(left)   <- !turn_left.
+!orient(bottom) : facing(right)  <- !turn_right.

+!turn_right <- !go(right).
+!turn_left  <- !go(left).
+!turn_back  <- !go(backward).


// ---------- MONSTER ESTIMATION ----------
+neighbour(Agent) : monster(Agent, _, _, alive) & not cur_target(Agent) <-
       .print("I found ", Agent, ", but it is not my current target...").

+neighbour(Agent) : monster(Agent, _, _, _, alive, _, _) & monster_power(Agent, _) & cur_target(Agent) <-
       .print("I returned to ", Agent);
       .print("Long time no see!");
       !fight(Agent).

+neighbour(Agent) : monster(Agent, _, _, _, alive, H, S) & cur_target(Agent) <-
       .print("I tracked ", Agent);
       .print("First contact with enemy...");
       .send(Agent, achieve, disclose_stats).

+monster_stats(H, S)[source(Agent)] : cur_health(MyH) & strength(MyS) <-
     .print("Aha! ", Agent, " has:");
     .print(H, " health and ", S, " strength");
     MonsterPower = H * S;
     MyPower = MyH * MyS;
     !choose_action(Agent, MonsterPower, MyPower).

+!choose_action(Agent, MonsterPower, MyPower) : MonsterPower <= MyPower <-
    .print("I am strong enough to attack ", Agent, "!");
    !fight(Agent).

+!choose_action(Agent, MonsterPower, MyPower) : MonsterPower > MyPower <-
    +monster_power(Agent, MonsterPower);
    .print("Monster is too strong! I retreat!");
    .print("...but I will return!");
    !kill_all_monsters.


// ---------- FIGHTING ----------
+!fight(Agent) : not in_battle(_) <-
    +in_battle(Agent);
    .print("I attack!");
    !attack.

+!attack : in_battle(Agent) & strength(S) <-
    .send(Agent, achieve, take_damage(S));
    .print("Aha! I caused ", S, " damage to ", Agent).

+!take_counter_damage(Dmg)[source(Agent)] : in_battle(Agent) & cur_health(HP) & max_health(MaxHP) <-
    NewHP = HP - Dmg;
    -+cur_health(NewHP);
    .print("Argh! Bastard! (HP: ", NewHP, "/", MaxHP, ")");
    !check_battle.

+!check_battle : cur_health(HP) & HP > 0 & in_battle(_) <-
    !attack.

+!check_battle : cur_health(HP) & HP <= 0 & in_battle(Monster) <-
    .print("I am defeated...");
    kill(self);
    -in_battle(Monster).

+!finish_fight[source(Monster)] <-
    !level_up;
    -in_battle(Monster);
    !kill_all_monsters.

+!level_up : max_health(MaxHP) & strength(Str) <-
    NewMaxHP = MaxHP + 75;
    NewStr = Str + 25;
    -+max_health(NewMaxHP);
    -+strength(NewStr);
    .print("LEVEL UP! Max health: ", NewMaxHP, " Strength: ", NewStr).


// ---------- MONSTER CONTRACT BELIEFS ----------
+monster(Name, Type, X, Y, alive, HP, STR) <-
    .print("I received contract to kill ", Name, " of type ", Type).

+monster(Name, Type, X, Y, dead, HP, STR) <-
    .print("I finished a contract for ", Name).