health(100).
strength(25).

+!show_level[source(Agent)] : health(HP) & strength(STR) <-
    .send(Agent, tell, monster_level(HP,STR)).