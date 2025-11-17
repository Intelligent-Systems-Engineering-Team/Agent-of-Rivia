health(100).
strength(25).

+!show_level[source(Agent)] : health(HP) & strength(STR) <-
    .send(Agent, tell, monster_level(HP,STR)).

+!get_damage(Dmg)[source(Agent)] : health(HP) & HP - Dmg > 0 <-
    NewHP = HP - Dmg;
    -health(HP);
    +health(NewHP);
    .print("Ouch! I received ", Dmg, " damage. My health is now ", NewHP).


+!get_damage(Dmg)[source(Agent)] : health(HP) & HP - Dmg >= 0 <-
    -+health(0);
    .my_name(Me);
    kill(Me);
    .print("I DIED").



+!fight_back[source(Agent)] : health(HP) & strength(STR) <-
    .print("Fighting back ", Agent).