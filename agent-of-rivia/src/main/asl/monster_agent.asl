health(75).
strength(25).

+!disclose_stats[source(Agent)] : health(H) & strength(S) <-
    .send(Agent, tell, monster_stats(H, S)).

+!take_damage(Dmg)[source(Agent)] : health(HP) & HP - Dmg > 0 & strength(S) <-
    NewHP = HP - Dmg;
    .print("Rrrrr! (HP: ", NewHP, ")");
    -health(HP);
    +health(NewHP);
    .print("ATTACKS*");
    .send(Agent, achieve, take_counter_damage(S)).


+!take_damage(Dmg)[source(Agent)] : health(HP) & HP - Dmg <= 0 <-
    -+health(0);
    .my_name(Me);
    .print(Me, " DEATH SOUND*");
    kill(Me);
    .send(Agent, achieve, finish_fight).