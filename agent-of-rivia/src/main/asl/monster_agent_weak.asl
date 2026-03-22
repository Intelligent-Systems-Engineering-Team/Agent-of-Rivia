health(75).
strength(25).

+!disclose_stats[source(Agent)] : health(H) & strength(S) <-
    .send(Agent, tell, monster_stats(H, S)).

+!take_damage(Dmg)[source(Agent)] : health(HP) & HP - Dmg > 0 & strength(S) <-
    NewHP = HP - Dmg;
    -+health(NewHP);
    .print("Rrrrrrr! (HP: ", NewHP, ")");
    .print("ATTACKS*");
    .send(Agent, achieve, take_counter_damage(S)).


+!take_damage(Dmg)[source(Agent)] : health(HP) & HP - Dmg <= 0 <-
    -+health(0);
    .my_name(Me);
    .print("DEATH SOUND*");
    .send(Agent, achieve, finish_fight);
    kill(Me).
