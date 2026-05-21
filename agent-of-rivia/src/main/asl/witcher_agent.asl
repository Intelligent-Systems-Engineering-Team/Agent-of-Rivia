max_health(75).
cur_health(75).
strength(25).

facing(top).
position(0, 0).

home(0, 0).
tavern(19, 0).

cur_target(none).

heal_threshold(0.75).

mode(idle).


// ---------- DERIVED BELIEFS ----------
healthy_enough :-
    cur_health(CurHP) &
    max_health(MaxHP) &
    heal_threshold(ThresholdHP) &
    CurHP >= MaxHP * ThresholdHP.

my_power(P) :-
    cur_health(H) &
    strength(S) &
    P = H * S.

can_hunt(Name) :-
    monster_power(Name, MonsterPower) &
    my_power(MyPower) &
    MyPower >= MonsterPower.

can_hunt(Name) :-
    not monster_power(Name, _).


// ---------- MAIN GOAL ----------
!kill_all_monsters.

+!kill_all_monsters : monster(_,_,_,alive) <-
    !ensure_ready;
    !hunt.

+!kill_all_monsters : not monster(_,_,_,alive) <-
    -+mode(celebrating);
    !celebrate;
    !go_home.


// ---------- PREPARATION ----------
+!ensure_ready : healthy_enough & mode(idle) <- true.

+!ensure_ready : not healthy_enough & mode(idle) <-
    .print("Health is below threshold, I am going to tavern...");
    -+mode(recovering);
    !go_tavern;
    !heal.

+!go_tavern : tavern(X, Y) & mode(recovering) <-
    !go_to(X, Y);
    .print("I am in tavern to recover.").


+!heal : max_health(MaxHP) & mode(recovering) <-
    -+cur_health(MaxHP);
    -+mode(idle);
    .print("Ate some food, drunk some ale! (HP: ", MaxHP, "/", MaxHP, ")").


// ---------- HUNTING ----------
+!hunt : monster(Name, X, Y, alive) & can_hunt(Name) <-
    -+mode(hunting);
    !set_target(Name);
    !track_target(X, Y).

+!hunt : monster(Name, _, _, alive) & not can_hunt(Name) <-
    .print("I am not ready to fight ", Name, " yet, skipping target...");
    !hunt.


+!set_target(Name) : mode(hunting) <-
    -+cur_target(Name);
    .print("My next target is ", Name, "!").

+!track_target(X, Y) : mode(hunting) <-
    .print("Tracking monster at: (", X, ", ", Y, ")");
    !go_to(X, Y).


// ---------- CELEBRATING ----------
+!celebrate : mode(celebrating) <-
    .print("Let's celebrate!");
    !go_tavern.

+!go_tavern : tavern(X, Y) & mode(celebrating) <-
    !go_to(X, Y);
    .print("I am in tavern to celebrate!").

+!go_home : home(Xt, Yt) & mode(celebrating) <-
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

+!go_to(Xt, Yt) : monster(Agent, Xt, Yt, alive) & neighbour(Agent) & cur_target(Agent) <-
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

+!turn_right : facing(top)    <- turn(right); -+facing(right).
+!turn_right : facing(right)  <- turn(right); -+facing(bottom).
+!turn_right : facing(bottom) <- turn(right); -+facing(left).
+!turn_right : facing(left)   <- turn(right); -+facing(top).

+!turn_left  : facing(top)    <- turn(left); -+facing(left).
+!turn_left  : facing(left)   <- turn(left); -+facing(bottom).
+!turn_left  : facing(bottom) <- turn(left); -+facing(right).
+!turn_left  : facing(right)  <- turn(left); -+facing(top).

+!turn_back  : facing(top)    <- turn(backward); -+facing(bottom).
+!turn_back  : facing(bottom) <- turn(backward); -+facing(top).
+!turn_back  : facing(left)   <- turn(backward); -+facing(right).
+!turn_back  : facing(right)  <- turn(backward); -+facing(left).


// ---------- MONSTER ESTIMATION ----------
+neighbour(Agent) : monster(Agent, _, _, alive) & cur_target(Agent) & not monster_power(Agent, _) <-
       .print("I tracked ", Agent);
       .print("First contact with enemy...");
       -+awaiting_stats(Agent);
       .send(Agent, achieve, disclose_stats).

+awaiting_stats(Agent) : cur_target(Agent) & monster(Agent, _, _, alive) & not monster_power(Agent, _) <-
       .wait(500);
       .send(Agent, achieve, disclose_stats);
       -+awaiting_stats(Agent).

+neighbour(Agent) : monster(Agent, _, _, alive) & monster_power(Agent, _) & cur_target(Agent) <-
       .print("I returned to ", Agent);
       .print("Long time no see!");
       !fight(Agent).

+neighbour(Agent) : monster(Agent, _, _, alive) & not cur_target(Agent) <-
       .print("I found ", Agent, ", but it is not my current target...").


+monster_stats(H, S)[source(Agent)] : cur_health(MyH) & strength(MyS) & not in_battle(_) & monster(Agent, _, _, alive) <-
     -awaiting_stats(Agent);
     .print("Aha! ", Agent, " has:");
     .print(H, " health and ", S, " strength");
     MonsterPower = H * S;
     MyPower = MyH * MyS;
     !choose_action(Agent, MonsterPower, MyPower).


+!choose_action(Agent, MonsterPower, MyPower) : MonsterPower <= MyPower <-
    .print("I am strong enough to fight ", Agent, "!");
    !fight(Agent).

+!choose_action(Agent, MonsterPower, MyPower) : MonsterPower > MyPower <-
    +monster_power(Agent, MonsterPower);
    .print("Monster is too strong! I retreat!");
    .print("...but I will return!");
    !hunt.


// ---------- FIGHTING ----------
+!fight(Agent) : in_battle(Agent) <- true.

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
    -+mode(idle);
    .print("LEVEL UP! Max health: ", NewMaxHP, " Strength: ", NewStr).


