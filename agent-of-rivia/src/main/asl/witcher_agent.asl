// ---------- INITIAL BELIEFS ----------
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

can_fight(Name) :-
    monster_power(Name, MonsterPower) &
    my_power(MyPower) &
    MyPower >= MonsterPower.

unknown_monster(Name) :-
    monster(Name, _, _, _, alive) &
    not known_monster(Name).


// ---------- MAIN GOAL ----------
!kill_all_monsters.

+!kill_all_monsters : monster(_, _, _, _, alive) <-
    !ensure_ready;
    !hunt.

+!kill_all_monsters : not monster(_, _, _, _, alive) <-
    !celebrate;
    !go_home.

// ---------- PREPARATION ----------
+!ensure_ready : healthy_enough <- true.

+!ensure_ready : not healthy_enough <-
    .print("Health is below threshold, I am going to tavern...");
    !go_tavern;
    !heal.

+!go_tavern : tavern(X, Y) <-
    -+cur_target(none);
    !go_to(X, Y);
    .print("Arrived at tavern.").

+!heal : max_health(MaxHP) <-
    -+cur_health(MaxHP);
    .print("Ate some food, drunk some ale! (HP: ", MaxHP, "/", MaxHP, ")").


// ---------- HUNTING ----------
+!hunt : unknown_monster(Name) & monster(Name, _, X, Y, alive) <-
    .print("Scouting unknown monster: ", Name);
    !set_target(Name);
    !track_target(X, Y).

+!hunt : not unknown_monster(_) &
         monster(Name, _, X, Y, alive) &
         can_fight(Name) <-
    .print("Hunting beatable monster: ", Name);
    !set_target(Name);
    !track_target(X, Y).

+!hunt : not unknown_monster(_) &
         monster(_, _, _, _, alive) &
         not can_fight(_) <-
    .print("No beatable monsters right now. Healing and retrying...");
    !go_tavern;
    !heal;
    !kill_all_monsters.

+!set_target(Name) <-
    -cur_target(_);
    +cur_target(Name);
    .print("Target set: ", Name).

+!track_target(X, Y) <-
    .print("Moving toward target at (", X, ", ", Y, ")");
    !go_to(X, Y).

// ---------- FIRST CONTACT / SCOUTING ----------

// Known current target: fight if beatable, otherwise retreat
+neighbour(Agent) : monster(Agent, _, _, _, alive) &
                    monster_power(Agent, Power) &
                    cur_target(Agent) &
                    my_power(MyPower) &
                    MyPower >= Power <-
    .print("Reached known beatable monster: ", Agent);
    !fight(Agent).

+neighbour(Agent) : monster(Agent, _, _, _, alive) &
                    monster_power(Agent, Power) &
                    cur_target(Agent) &
                    my_power(MyPower) &
                    Power > MyPower <-
    .print(Agent, " is still too strong. Retreating.");
    !retreat_and_recover.

// Unknown current target: ask for stats
+neighbour(Agent) : monster(Agent, _, _, _, alive) &
                    not known_monster(Agent) &
                    cur_target(Agent) <-
    +known_monster(Agent);
    .print("First contact with ", Agent, ". Requesting stats...");
    .send(Agent, achieve, disclose_stats).

// Other monster nearby: ignore
+neighbour(Agent) : monster(Agent, _, _, _, alive) &
                    not cur_target(Agent) <-
    .print("Spotted ", Agent, ", but it is not my current target.").

// ---------- MONSTER STATS DECISION ----------

+monster_stats(H, S)[source(Agent)] : cur_health(MyH) & strength(MyS) <-
    .print(Agent, " revealed stats: HP=", H, " STR=", S);
    MonsterPower = H * S;
    MyPower = MyH * MyS;
    -monster_power(Agent, _);
    +monster_power(Agent, MonsterPower);
    !choose_action(Agent, MonsterPower, MyPower).

+!choose_action(Agent, MonsterPower, MyPower) : MonsterPower <= MyPower <-
    .print("I can defeat ", Agent, ". Attacking.");
    !fight(Agent).

+!choose_action(Agent, MonsterPower, MyPower) : MonsterPower > MyPower <-
    .print(Agent, " is too strong. Monster power: ", MonsterPower, ", my power: ", MyPower);
    !retreat_and_recover.

// ---------- RETREAT ----------
+!retreat_and_recover <-
    .print("I retreat!");
    .print("...but I will return!");
    -cur_target(_);
    +cur_target(none);
    !go_tavern;
    !heal;
    !kill_all_monsters.

// ---------- FIGHTING ----------

+!fight(Agent) : not in_battle(_) <-
    +in_battle(Agent);
    .print("Engaging ", Agent, "!");
    !attack.

+!fight(Agent) : in_battle(Agent) <-
    .print("Already fighting ", Agent).

+!fight(Agent) : in_battle(Other) & not in_battle(Agent) <-
    .print("Cannot fight ", Agent, ". Already fighting ", Other).

+!attack : in_battle(Agent) & strength(S) <-
    .send(Agent, achieve, take_damage(S));
    .print("Struck ", Agent, " for ", S, " damage.").

+!take_counter_damage(Dmg)[source(Agent)] : in_battle(Agent) &
                                             cur_health(HP) &
                                             max_health(MaxHP) <-
    NewHP = HP - Dmg;
    -+cur_health(NewHP);
    .print("Counter-hit by ", Agent, ". HP: ", NewHP, "/", MaxHP);
    !check_battle.

+!check_battle : cur_health(HP) & HP > 0 & in_battle(_) <-
    !attack.

+!check_battle : cur_health(HP) & HP <= 0 & in_battle(Monster) <-
    .print("Defeated by ", Monster, "...");
    -in_battle(Monster);
    kill(self).

+!finish_fight[source(Monster)] <-
    .print("Defeated ", Monster, "!");
    !level_up;
    -in_battle(Monster);
    -known_monster(Monster);
    -monster_power(Monster, _);
    -cur_target(_);
    +cur_target(none);
    !kill_all_monsters.

+!level_up : max_health(MaxHP) & strength(Str) <-
    NewMaxHP = MaxHP + 75;
    NewStr = Str + 25;
    -+max_health(NewMaxHP);
    -+cur_health(NewMaxHP);
    -+strength(NewStr);
    .print("LEVEL UP! HP: ", NewMaxHP, " STR: ", NewStr).



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
    .print("Move failed. Retrying...");
    !go(Direction).

// Stop next to a live monster instead of stepping onto its tile
+!go_to(Xt, Yt) : position(X, Y) &
                   monster(_, _, Xt, Yt, alive) &
                   adjacent(X, Y, Xt, Yt) <-
    .print("Adjacent to monster at (", Xt, ", ", Yt, "). Stopping.").

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
+neighbour(Agent) : monster(Agent, _, _, _, alive, _, _) &
                    not cur_target(Agent) <-
    .print("I found ", Agent, ", but it is not my current target...").

+neighbour(Agent) : monster(Agent, _, _, _, alive, _, _) &
                    cur_target(Agent) &
                    can_hunt(Agent) <-
    .print("I tracked ", Agent);
    .print("I am strong enough to attack!");
    !fight(Agent).

+neighbour(Agent) : monster(Agent, _, _, _, alive, _, _) &
                    cur_target(Agent) &
                    not can_hunt(Agent) <-
    .print("I tracked ", Agent);
    .print("Monster is too strong!");
    !retreat_and_recover.

// ---------- CONTRACT LOG ----------

+monster(Name, Type, X, Y, alive) <-
    .print("Contract available: ", Name, " (", Type, ") at (", X, ",", Y, ")").

+monster(Name, Type, X, Y, dead) <-
    .print("Contract closed: ", Name, " (", Type, ")").