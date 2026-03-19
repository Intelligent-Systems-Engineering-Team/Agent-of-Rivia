+!disclose_stats[source(Agent)] : self_stats(H, S) <-
    .send(Agent, tell, monster_stats(H, S)).

+!take_damage(Dmg)[source(Agent)] : self_stats(HP, S) & HP - Dmg > 0 <-
    apply_damage(Dmg);
    NewHP = HP - Dmg;
    .print("Rrrrrrr! (HP: ", NewHP, ")");
    .print("ATTACKS*");
    .send(Agent, achieve, take_counter_damage(S)).

+!take_damage(Dmg)[source(Agent)] : self_stats(HP, _) & HP - Dmg <= 0 <-
    .my_name(Me);
    .print("DEATH SOUND*");
    .send(Agent, achieve, finish_fight);
    kill(Me).